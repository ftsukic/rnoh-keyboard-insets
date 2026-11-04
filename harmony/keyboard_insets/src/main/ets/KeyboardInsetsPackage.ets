import {
  EtsUITurboModule,
  RNOHPackage,
  type UITurboModule,
  type UITurboModuleContext,
} from '@rnoh/react-native-openharmony';

import type { AnimatorResult } from '@ohos.animator';
import { KeyboardAvoidMode, type UIContext } from '@ohos.arkui.UIContext';
import window from '@ohos.window';

const KEYBOARD_ANIMATION_DURATION_MS = 566;
const KEYBOARD_ANIMATION_EASING = 'ease-out';

class KeyboardInsetsObserver extends EtsUITurboModule {
  private windowInstance?: window.Window;
  private uiContext?: UIContext;
  private keyboardHeightChange?: (height: number) => void;
  private animator?: AnimatorResult;
  private destroyed = false;
  private currentPositionPx = 0;
  private stableKeyboardHeightPx = 0;
  private lastNonZeroKeyboardHeightPx = 0;
  private targetPositionPx = 0;
  private targetHeightPx = 0;
  private targetShown = false;
  private currentShown = false;
  private transitioning = false;
  private transitionGeneration = 0;

  constructor(ctx: UITurboModuleContext) {
    super(ctx);
    this.initialize().catch((error: Error) => {
      console.error(`[KeyboardInsetsObserver] initialize failed: ${String(error)}`);
    });
  }

  private async initialize() {
    const rnWindow = await this.ctx.rnInstance.getRNWindow();
    if (this.destroyed) {
      return;
    }
    this.windowInstance = rnWindow;
    this.uiContext = rnWindow.getUIContext();

    this.keyboardHeightChange = (keyboardHeight: number) => {
      this.handleKeyboardHeightChange(keyboardHeight);
    };
    rnWindow.on('keyboardHeightChange', this.keyboardHeightChange);

    const initialArea = rnWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_KEYBOARD);
    this.publishStableState(
      initialArea.bottomRect.height,
      initialArea.bottomRect.height > 0,
    );
  }

  private handleKeyboardHeightChange(keyboardHeight: number) {
    const targetPositionPx = Math.max(keyboardHeight, 0);
    const targetShown = targetPositionPx > 0;
    if (targetShown) {
      this.lastNonZeroKeyboardHeightPx = targetPositionPx;
    }

    const targetHeightPx = targetShown
      ? targetPositionPx
      : this.getHideMetadataHeightPx();
    this.startTransition(targetPositionPx, targetHeightPx, targetShown);
  }

  private getHideMetadataHeightPx(): number {
    if (this.transitioning && this.targetShown && this.targetHeightPx > 0) {
      return this.targetHeightPx;
    }
    if (this.stableKeyboardHeightPx > 0) {
      return this.stableKeyboardHeightPx;
    }
    return this.lastNonZeroKeyboardHeightPx;
  }

  private publishStableState(
    rawPositionPx: number,
    shown: boolean,
  ) {
    const positionPx = shown ? Math.max(rawPositionPx, 0) : 0;
    if (shown) {
      this.stableKeyboardHeightPx = positionPx;
      this.lastNonZeroKeyboardHeightPx = positionPx;
    }
    this.currentPositionPx = positionPx;
    this.currentShown = shown;
    this.targetPositionPx = positionPx;
    this.targetHeightPx = shown ? positionPx : this.stableKeyboardHeightPx;
    this.targetShown = shown;
    this.transitioning = false;
    this.postKeyboardState(positionPx, this.targetHeightPx, shown, false);
  }

  private postKeyboardState(
    positionPx: number,
    heightPx: number,
    shown: boolean,
    transitioning: boolean,
  ) {
    this.ctx.rnInstance.postMessageToCpp('KeyboardInsets::KeyboardChanged', {
      position: px2vp(positionPx),
      height: px2vp(heightPx),
      shown,
      transitioning,
      systemAvoidsKeyboard:
        this.uiContext?.getKeyboardAvoidMode() !== KeyboardAvoidMode.NONE,
    });
  }

  private isCurrentTransition(generation: number): boolean {
    return !this.destroyed && this.transitioning && generation === this.transitionGeneration;
  }

  private startTransition(
    targetPositionPx: number,
    targetHeightPx: number,
    targetShown: boolean,
  ) {
    if (this.destroyed) {
      return;
    }

    if (
      this.transitioning &&
      targetPositionPx === this.targetPositionPx &&
      targetHeightPx === this.targetHeightPx &&
      targetShown === this.targetShown
    ) {
      return;
    }
    if (
      !this.transitioning &&
      targetPositionPx === this.currentPositionPx &&
      targetShown === this.currentShown
    ) {
      return;
    }

    this.transitionGeneration += 1;
    const generation = this.transitionGeneration;
    this.cancelAnimator();

    const beginPositionPx = this.currentPositionPx;
    this.targetPositionPx = targetPositionPx;
    this.targetHeightPx = targetHeightPx;
    this.targetShown = targetShown;
    this.currentShown = targetShown;
    this.transitioning = true;

    // Establish the status boundary before the first native position frame.
    this.postKeyboardState(
      beginPositionPx,
      targetHeightPx,
      targetShown,
      true,
    );

    if (beginPositionPx === targetPositionPx) {
      this.finishTransition(generation);
      return;
    }

    const uiContext = this.uiContext;
    if (uiContext === undefined) {
      console.error('[KeyboardInsetsObserver] animator creation skipped: UI context unavailable');
      this.finishTransition(generation);
      return;
    }

    let animator: AnimatorResult;
    try {
      animator = uiContext.createAnimator({
        duration: KEYBOARD_ANIMATION_DURATION_MS,
        easing: KEYBOARD_ANIMATION_EASING,
        delay: 0,
        fill: 'forwards',
        direction: 'normal',
        iterations: 1,
        begin: beginPositionPx,
        end: targetPositionPx,
      });
    } catch (error) {
      console.error(`[KeyboardInsetsObserver] animator creation failed: ${String(error)}`);
      this.finishTransition(generation);
      return;
    }

    this.animator = animator;
    animator.onFrame = (value: number) => {
      if (!this.isCurrentTransition(generation)) {
        return;
      }
      const positionPx = Math.max(value, 0);
      this.currentPositionPx = positionPx;
      this.postKeyboardState(
        positionPx,
        targetHeightPx,
        targetShown,
        true,
      );
    };
    animator.onFinish = () => {
      this.finishTransition(generation);
    };
    animator.onCancel = () => {
      if (!this.isCurrentTransition(generation)) {
        return;
      }
      this.animator = undefined;
      this.transitioning = false;
      this.postKeyboardState(
        this.currentPositionPx,
        targetHeightPx,
        targetShown,
        false,
      );
    };

    try {
      animator.play();
    } catch (error) {
      console.error(`[KeyboardInsetsObserver] animator play failed: ${String(error)}`);
      this.animator = undefined;
      this.finishTransition(generation);
    }
  }

  private finishTransition(generation: number) {
    if (!this.isCurrentTransition(generation)) {
      return;
    }

    const targetPositionPx = this.targetPositionPx;
    const targetHeightPx = this.targetHeightPx;
    const targetShown = this.targetShown;
    this.currentPositionPx = targetPositionPx;
    this.currentShown = targetShown;
    if (targetShown) {
      this.stableKeyboardHeightPx = targetHeightPx;
      this.lastNonZeroKeyboardHeightPx = targetHeightPx;
    }
    this.animator = undefined;
    this.transitioning = false;
    this.postKeyboardState(
      targetPositionPx,
      targetHeightPx,
      targetShown,
      false,
    );
  }

  private cancelAnimator() {
    const oldAnimator = this.animator;
    this.animator = undefined;
    if (oldAnimator === undefined) {
      return;
    }

    // cancel() may synchronously invoke callbacks or emit its terminal frame.
    // Detach them before canceling; transitionGeneration already invalidated
    // this animator before this method is called.
    oldAnimator.onFrame = () => {};
    oldAnimator.onFinish = () => {};
    oldAnimator.onCancel = () => {};
    try {
      oldAnimator.cancel();
    } catch (error) {
      console.error(`[KeyboardInsetsObserver] animator cancellation failed: ${String(error)}`);
    }
  }

  override __onDestroy__() {
    this.destroyed = true;
    this.transitionGeneration += 1;
    this.cancelAnimator();
    const rnWindow = this.windowInstance;
    if (rnWindow !== undefined) {
      if (this.keyboardHeightChange !== undefined) {
        rnWindow.off('keyboardHeightChange', this.keyboardHeightChange);
      }
    }
    this.windowInstance = undefined;
    this.uiContext = undefined;
    this.keyboardHeightChange = undefined;
    super.__onDestroy__();
  }
}

/**
 * Registers the Harmony component package and the keyboard observer module.
 */
export class KeyboardInsetsPackage extends RNOHPackage {
  override async createEagerUITurboModuleByNameMap(
    ctx: UITurboModuleContext,
  ): Promise<Map<string, UITurboModule>> {
    return new Map([['KeyboardInsetsObserver', new KeyboardInsetsObserver(ctx)]]);
  }
}

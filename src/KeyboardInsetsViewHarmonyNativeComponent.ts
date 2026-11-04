import { codegenNativeComponent } from 'react-native';
import type { ViewProps } from 'react-native';
import type { CodegenTypes } from 'react-native';

interface KeyboardInsetsViewHarmonyProps extends ViewProps {
	mode?: CodegenTypes.WithDefault<'auto' | 'manual', 'auto'>;
	extraHeight?: CodegenTypes.WithDefault<CodegenTypes.Float, 0>;
	explicitly?: CodegenTypes.WithDefault<boolean, false>;
	onPositionChanged?: CodegenTypes.BubblingEventHandler<{
		position: CodegenTypes.Float;
	}>;
	onStatusChanged?: CodegenTypes.DirectEventHandler<{
		height: CodegenTypes.Float;
		shown: boolean;
		transitioning: boolean;
	}>;
}

/**
 * Harmony library codegen entry point.
 *
 * The public component continues to use KeyboardInsetsViewNativeComponent.
 * This spec is intentionally separate because Harmony C-API codegen requires
 * a concrete component spec while the shared React Native spec is interface-only.
 */
export default codegenNativeComponent<KeyboardInsetsViewHarmonyProps>(
	'KeyboardInsetsView',
);

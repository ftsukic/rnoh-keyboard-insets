# @ftsukic/rnoh-keyboard-insets

面向 React Native OpenHarmony（RNOH）的键盘避让组件，基于 `KeyboardInsetsView` 原有 JS API，并提供 Harmony C-API 原生实现。本仓库只包含 RNOH 适配，不包含 Android 或 iOS 原生实现。

## 兼容版本

| 包版本 | React Native | RNOH | 架构 |
| --- | --- | --- | --- |
| 0.1.x | 0.82.1 | 0.82.33 | C-API |

## 安装

```bash
yarn add @ftsukic/rnoh-keyboard-insets
```

## Harmony 工程接入

RNOH 当前不支持三方库 AutoLink，需按 [RNOH 三方库接入文档](https://github.com/react-native-oh-library/react-native-harmony-screens/blob/sig/doc/en.md) 手动链接和注册。本库使用源码链接，不依赖预编译 HAR。

1. 在 `harmony/entry/oh-package.json5` 的 `dependencies` 中加入本库，保留工程已有的 `@rnoh/react-native-openharmony` 依赖和根目录 `overrides`：

   ```json5
   "@rnoh/react-native-keyboard-insets": "file:../../node_modules/@ftsukic/rnoh-keyboard-insets/harmony/keyboard_insets"
   ```

   然后在 Harmony 工程目录运行 `ohpm install --all`。

2. 在 `harmony/entry/src/main/cpp/CMakeLists.txt` 中，RNOH 的 `rnoh` target 定义后加入源码目录和链接目标：

   ```cmake
   set(OH_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules")
   add_subdirectory(
       "${OH_MODULES}/@rnoh/react-native-keyboard-insets/src/main/cpp"
       ./rnoh_keyboard_insets)
   target_link_libraries(rnoh_app PUBLIC rnoh__keyboard_insets)
   ```

3. 在 `PackageProvider.cpp` 注册 C++ 包：

   ```cpp
   #include "ReactNativeKeyboardInsetsPackage.h"

   // 在 PackageProvider::getPackages(ctx) 返回的列表中加入：
   std::make_shared<rnoh::ReactNativeKeyboardInsetsPackage>(ctx)
   ```

4. 在 `RNOHPackagesFactory.ets` 注册 ArkTS 包：

   ```ts
   import KeyboardInsetsPackage from '@rnoh/react-native-keyboard-insets';

   // 在 createRNOHPackages(ctx) 返回的列表中加入：
   new KeyboardInsetsPackage(ctx)
   ```

RNOH 的 `KeyboardAvoidMode.OFFSET` 和 `RESIZE` 由系统避让键盘，本库不会重复移动容器。若应用将模式设为 `KeyboardAvoidMode.NONE`，本库会根据当前焦点输入框的位置移动最近的 `KeyboardInsetsView`。库不会修改应用的窗口级键盘模式。

## 使用

```tsx
import { KeyboardInsetsView } from '@ftsukic/rnoh-keyboard-insets';

function Form() {
  return (
    <KeyboardInsetsView extraHeight={16} style={{ flex: 1 }}>
      <ScrollView>
        <TextInput />
      </ScrollView>
    </KeyboardInsetsView>
  );
}
```

`KeyboardInsetsView` 可嵌套使用。自动模式会处理最近容器中的焦点输入框；设置 `onKeyboard` 后进入手动模式，由回调提供键盘状态和动画位置。

```tsx
import { KeyboardInsetsView, useKeyboard } from '@ftsukic/rnoh-keyboard-insets';

function Form() {
  const { keyboard, onKeyboard } = useKeyboard();

  return (
    <KeyboardInsetsView onKeyboard={onKeyboard}>
      <TextInput />
    </KeyboardInsetsView>
  );
}
```

手动模式的状态包含 `height`、`shown`、`transitioning` 和 `position`（`Animated.Value`）。`explicitly` 属性保留用于兼容原有 JS API，在 RNOH 上不生效。

## License

MIT

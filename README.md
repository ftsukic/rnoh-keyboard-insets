# @ftsukic/rnoh-keyboard-insets

面向 React Native OpenHarmony（RNOH）的键盘避让组件，基于 `KeyboardInsetsView` 原有 JS API，并提供 Harmony C-API 原生实现。本仓库只包含 RNOH 适配，不包含 Android 或 iOS 原生实现。

## 兼容版本

| 包版本 | React Native | RNOH | 架构 |
| --- | --- | --- | --- |
| 0.1.x | 0.82.1 | 0.82.33 | C-API |

## 安装

包目前尚未发布到 npm，先在项目 `package.json` 中添加 GitHub 依赖：

```json
{
  "dependencies": {
    "@ftsukic/rnoh-keyboard-insets": "git+https://github.com/ftsukic/rnoh-keyboard-insets.git#main"
  }
}
```

然后运行 `yarn install`。

## Harmony 工程接入

本库提供预编译 HAR 和 RNOH AutoLink 配置。已接入 RNOH AutoLink 的工程不需要手动编辑 `oh-package.json5`、CMake 或包工厂；RNOH 的 Hvigor 插件会调用 `link-harmony` 生成依赖和注册代码。请先确认工程已按 [RNOH AutoLink 文档](https://gitcode.com/openharmony-sig/ohos_react_native/blob/master/docs/zh-cn/Autolinking.md) 接入 AutoLink（通常由 `harmony/entry/hvigorfile.ts` 中的 `createRNOHModulePlugin()` 提供）。

1. 在 React Native 工程根目录安装本包：

   ```bash
   yarn add @ftsukic/rnoh-keyboard-insets@git+https://github.com/ftsukic/rnoh-keyboard-insets.git#main
   ```

2. 在 React Native 工程根目录运行 AutoLink 命令：

   ```bash
   npx react-native link-harmony --harmony-project-path ./harmony
   ```

   RNOH Hvigor 插件会在同步阶段自动运行同一命令；手动运行可立即生成配置。然后在 Harmony 工程目录安装 HAR 依赖：

   ```bash
   cd harmony
   ohpm install --all
   ```

   `link-harmony` 会把 HAR 添加到 Harmony 根目录的 `oh-package.json5`，并生成 CMake、C++ 和 ArkTS 包工厂注册。完成后按原有方式构建 Harmony 应用。

本包的 HAR 由 RNOH 0.82.33 构建，使用时保留工程对 `@rnoh/react-native-openharmony` 的版本约束或 `overrides`。

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

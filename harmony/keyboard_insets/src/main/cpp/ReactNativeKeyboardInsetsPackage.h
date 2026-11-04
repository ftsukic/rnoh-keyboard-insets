#pragma once

#include "KeyboardInsetsViewComponentInstance.h"
#include "RNOH/generated/BaseRnohReactNativeKeyboardInsetsPackage.h"

namespace rnoh {

class ReactNativeKeyboardInsetsPackage final
    : public BaseRnohReactNativeKeyboardInsetsPackage {
 public:
  using BaseRnohReactNativeKeyboardInsetsPackage::
      BaseRnohReactNativeKeyboardInsetsPackage;

  ComponentInstance::Shared createComponentInstance(
      const ComponentInstance::Context& ctx) override {
    if (ctx.componentName == "KeyboardInsetsView") {
      return std::make_shared<KeyboardInsetsViewComponentInstance>(ctx);
    }
    return nullptr;
  }
};

} // namespace rnoh

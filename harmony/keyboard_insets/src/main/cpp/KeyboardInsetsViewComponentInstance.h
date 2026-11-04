#pragma once

#include "RNOH/ArkTSMessageHub.h"
#include "RNOH/CppComponentInstance.h"
#include "RNOH/arkui/CustomNode.h"
#include "RNOH/generated/components/BaseKeyboardInsetsViewComponentInstance.h"

namespace facebook::react {
class KeyboardInsetsViewProps;
}

namespace rnoh {

class KeyboardInsetsViewComponentInstance final
    : public BaseKeyboardInsetsViewComponentInstance,
      public ArkTSMessageHub::Observer {
 public:
  KeyboardInsetsViewComponentInstance(Context context);

  void onPropsChanged(SharedConcreteProps const& props) override;
  void onLayoutChanged(
      facebook::react::LayoutMetrics const& layoutMetrics) override;

  void onChildInserted(ComponentInstance::Shared const& childComponentInstance,
                       std::size_t index) override;
  void onChildRemoved(
      ComponentInstance::Shared const& childComponentInstance) override;
  CustomNode& getLocalRootArkUINode() override;

  void onMessageReceived(ArkTSMessage const& message) override;

 private:
  void updateAutoTranslation(
      facebook::react::KeyboardInsetsViewProps const& props,
      float containerHeight);

  CustomNode m_customNode;
  float m_lastPosition = 0;
  float m_lastHeight = 0;
  bool m_lastShown = false;
  bool m_lastTransitioning = false;
  bool m_systemAvoidsKeyboard = true;
  bool m_hasKeyboardState = false;
  bool m_manualKeyboardRelevant = false;
};

} // namespace rnoh

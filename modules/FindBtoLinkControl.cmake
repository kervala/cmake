SET(BTOLINKCONTROL_DIR ${BTOLINK_CONTROL_DIR})

IF(USE_MFC)
  SET(LIBRARIES BtoLinkControlManager_win32 BtoLinkControlManager_win32d)
ELSE(USE_MFC)
  SET(LIBRARIES BtoLinkControlManager_qt BtoLinkControlManager_qtd)
ENDIF(USE_MFC)

FIND_PACKAGE_HELPER(BtoLinkControl btolinkmanager.h ${LIBRARIES})

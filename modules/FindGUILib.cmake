FIND_PACKAGE_HELPER(GUILib GuiLib.h)

IF(GUILIB_FOUND)
  SET(GUILIB_DEFINITIONS "-D_GUILIB_NOAUTOLIB")
ENDIF(GUILIB_FOUND)

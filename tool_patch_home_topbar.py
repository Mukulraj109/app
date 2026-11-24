from pathlib import Path

# Facts for this edit (existing files only):
# 1. Callers: focus_shell.dart -> FocusHomeView; home_top.dart is part of
#    focus_home_view.dart and _TopBar is built around line 58.
# 2. Not a new top bar — updates the existing _TopBar to match 02-home.html.
# 3. No data-file I/O.
# 4. User: "use the html and we need to update the topbar of the home tab"

root = Path(__file__).resolve().parent
view = root / "lib" / "features" / "home" / "focus_home_view.dart"
top = root / "lib" / "features" / "home" / "widgets" / "home_top.dart"

text = view.read_text(encoding="utf-8")
old_imp = (
    "import '../profile/screens/profile_screens.dart';\n"
    "import 'home_store.dart';"
)
new_imp = (
    "import '../profile/screens/profile_screens.dart';\n"
    "import '../welcome/widgets/firststep_logo.dart';\n"
    "import 'home_store.dart';"
)
if "firststep_logo.dart" not in text:
    if old_imp not in text:
        raise SystemExit("import anchor missing in focus_home_view.dart")
    view.write_text(text.replace(old_imp, new_imp, 1), encoding="utf-8")
    print("focus_home_view: import added")
else:
    print("focus_home_view: import already present")

src = top.read_text(encoding="utf-8")
start = src.find(
    "  @override\n"
    "  Widget build(BuildContext context) {\n"
    "    final t = tokens;\n"
    "    return Row("
)
end = src.find("class _DotButton")
if start < 0 or end < 0:
    raise SystemExit(f"anchors not found start={start} end={end}")

replacement = r"""  @override
  Widget build(BuildContext context) {
    final t = tokens;
    // Match 02-home.html Option A (hdC + gC):
    // Row 1: News · centred FirstStep logo · Notifications
    // Row 2: centred greeting + plan line
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
          child: Row(
            children: [
              _DotButton(
                icon: Icons.article_outlined,
                label: 'News',
                hasDot: true,
                onTap: () => openNewsFeed(context),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onLongPress: () => _openStatePicker(context),
                    onDoubleTap: () => _openStatePicker(context),
                    child: const FirstStepLogo(
                      triangleWidth: 24,
                      wordmarkWidth: 112,
                      spacing: 7,
                    ),
                  ),
                ),
              ),
              _DotButton(
                icon: Icons.notifications_none_rounded,
                label: 'Notifications',
                hasDot: true,
                onTap: () => openNotifications(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '$_greeting, ${content.firstName}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: t.ink,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          content.planLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: t.mute,
          ),
        ),
      ],
    );
  }
}

"""

top.write_text(src[:start] + replacement + src[end:], encoding="utf-8")
print("home_top: _TopBar rebuilt to HTML Option A")

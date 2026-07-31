/// One onboarding slide: an illustration and its copy.
///
/// Titles and bodies are translation keys, so the En / Spa toggle swaps them
/// live without rebuilding the list.
class OnboardingPage {
  const OnboardingPage({
    required this.image,
    required this.titleKey,
    required this.bodyKey,
  });

  final String image;
  final String titleKey;
  final String bodyKey;
}

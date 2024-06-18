import 'package:cores_navigation/navigators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/router/provider/router.dart';

final class HomeNavigatorImpl implements HomeNavigator {
  const HomeNavigatorImpl();

  @override
  void goDebugPage(BuildContext context) {
    const DebugPageRoute().go(context);
  }

  @override
  void goWebPage(BuildContext context) {
    const WebPageRoute().go(context);
  }

  @override
  void goGitHubRepositoryDetailPage(
    BuildContext context,
    String repositoryName,
    String? description,
  ) {
    GitHubRepositoryDetailPageRoute(repositoryName, description).go(context);
  }
}

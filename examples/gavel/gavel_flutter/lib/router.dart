import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'core/api.dart';
import 'core/auction_scope.dart';
import 'core/auth_redirects.dart';
import 'pages/big_screen_board.dart';
import 'pages/board_page.dart';
import 'pages/create_auction_page.dart';
import 'pages/demo_page.dart';
import 'pages/home_page.dart';
import 'pages/lot_page.dart';
import 'pages/my_auctions_page.dart';
import 'pages/organizer_page.dart';
import 'pages/sign_in_page.dart';

/// The app's routes. The join link `/a/<CODE>` is the whole funnel.
final router = GoRouter(
  // Runs the redirects again on sign-in and sign-out (X6).
  refreshListenable: client.auth.authInfoListenable,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomePage()),
    // Only the organizer's pages need an account; bidders never sign in.
    GoRoute(
      path: '/new',
      redirect: (_, state) =>
          requireSignIn(client.auth.isAuthenticated, state.uri),
      builder: (_, _) => const CreateAuctionPage(),
    ),
    // The signed-in organizer's auctions, from any browser (UC-15).
    GoRoute(
      path: '/mine',
      redirect: (_, state) =>
          requireSignIn(client.auth.isAuthenticated, state.uri),
      builder: (_, _) => const MyAuctionsPage(),
    ),
    GoRoute(
      path: '/sign-in',
      redirect: (_, state) =>
          leaveSignIn(client.auth.isAuthenticated, state.uri),
      builder: (_, _) => const SignInPage(),
    ),
    // Always an open auction to try (X2).
    GoRoute(path: '/demo', builder: (_, _) => const DemoPage()),
    // Every page of one auction shares its controller, and so one live
    // subscription.
    ShellRoute(
      builder: (_, state, child) => AuctionScope(
        // A retyped code is a new auction, not an update of this one.
        key: ValueKey(_code(state)),
        code: _code(state),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/a/:code',
          // `?screen=board` is the projector's view, which nobody joins
          // from (UC-11).
          builder: (_, state) => state.uri.queryParameters['screen'] == 'board'
              ? BigScreenBoard(code: _code(state))
              : BoardPage(code: _code(state)),
          routes: [
            GoRoute(
              path: 'lot/:lotId',
              builder: (_, state) => LotPage(
                code: _code(state),
                lotId: state.pathParameters['lotId']!,
              ),
            ),
            GoRoute(
              path: 'organizer',
              builder: (_, state) => OrganizerPage(code: _code(state)),
            ),
          ],
        ),
      ],
    ),
  ],
);

String _code(GoRouterState state) =>
    state.pathParameters['code']!.toUpperCase();

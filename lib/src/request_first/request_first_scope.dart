import 'package:flutter/widgets.dart';
import 'package:reality_diorama/src/request_first/request_first_controller.dart';

class RequestFirstScope extends InheritedNotifier<RequestFirstController> {
  const RequestFirstScope({
    required RequestFirstController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static RequestFirstController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<RequestFirstScope>();
    assert(scope != null, 'RequestFirstScope is missing from the widget tree.');
    return scope!.notifier!;
  }

  static RequestFirstController read(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<RequestFirstScope>();
    final scope = element?.widget as RequestFirstScope?;
    assert(scope != null, 'RequestFirstScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}

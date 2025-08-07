enum ActionresultEnum { add, update, delete, none }

class Actionresult<T> {
  final  ActionresultEnum actionresultEnum;
  final T? data;
  final String? error;

  Actionresult({required this.actionresultEnum, this.data, this.error});
}
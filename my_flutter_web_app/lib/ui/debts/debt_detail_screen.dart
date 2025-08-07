
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_flutter_web_app/models/actionResult.dart';
import 'package:my_flutter_web_app/models/payment.dart';
import 'package:provider/provider.dart';
import '../../models/debt.dart' as model_debt;
import '../../providers/debt_notifier.dart';
import '../../providers/category_notifier.dart';
import '../../models/category.dart' as model_cat;
import './add_edit_debt_screen.dart';
import './add_payment_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../../services/notification_service.dart'; // Import NotificationService

class DebtDetailScreen extends StatefulWidget {
  final model_debt.Debt debt;
  final  Function(Actionresult<model_debt.Debt>) callback;

  const DebtDetailScreen({Key? key, required this.debt, required this.callback}) : super(key: key);  

  @override
  _DebtDetailScreenState createState() => _DebtDetailScreenState();
}

class _DebtDetailScreenState extends State<DebtDetailScreen> {
  late model_debt.Debt debt;

      @override
  void initState() {
    super.initState();
    debt = widget.debt;
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value, {bool isAmount = false, Color? amountColor}) {
    final textTheme = Theme.of(context).textTheme;
    if (value == null || value.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          Expanded(
            flex: 3,
            child: Text(value, style: isAmount ? textTheme.bodyLarge?.copyWith(color: amountColor, fontWeight: FontWeight.bold) : textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'de_DE'); 
    final dateFormat = DateFormat.yMMMMd();
    final debtNotifier = Provider.of<DebtNotifier>(context, listen: false);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    bool isOverdue = false;
    if(debt.dueDate != null) {
      isOverdue = debt.dueDate!.isBefore(DateTime.now()) && !debt.isPayed;
    }
    String debtStatusText;
    Color statusColor;

    if (debt.isPayed) {
      debtStatusText = "Paid";
      statusColor = Colors.green[700]!;
    } else if (debt.restAmount <= 0) {
      debtStatusText = "Paid (Pending Verification)";
      statusColor = Colors.green[700]!;
    } else if (isOverdue) {
      debtStatusText = "Overdue";
      statusColor = Colors.orange[700]!;
    } else {
      debtStatusText = "Pending";
      statusColor = colorScheme.primary; 
    }
    double progress = debt.amount > 0 ? (debt.payedAmount / debt.amount).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.creditor),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            tooltip: 'Edit Debt',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditDebtScreen(debtToEdit: debt, callback: (_) {}),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete, color: colorScheme.error),
            tooltip: 'Delete Debt',
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: Text('Confirm Delete', style: textTheme.titleLarge),
                    content: Text('Are you sure you want to delete this debt "${debt.creditor}"?', style: textTheme.bodyLarge),
                    actions: <Widget>[
                      TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(ctx).pop()),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(ctx); 
                          final rootNavigator = Navigator.of(context); 

                          debtNotifier.deleteDebt(debt.id!).then((_){
                             scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Debt "${debt.creditor}" deleted.'), backgroundColor: Colors.green)
                             );

                             widget.callback.call(Actionresult(actionresultEnum: ActionresultEnum.delete, data: widget.debt));
                             navigator.pop(); 
                             rootNavigator.pop(); 
                          }).catchError((error){
                             scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('Error deleting debt: $error'), backgroundColor: Colors.redAccent)
                             );
                             navigator.pop(); 
                          });
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card( 
              elevation: Theme.of(context).cardTheme.elevation ?? 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(child: Text(debt.creditor, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary))),
                    if (debt.comment != null && debt.comment!.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(top: 8.0, bottom: 12.0), child: Text(debt.comment!, style: textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic))),
                    Divider(),
                    _buildDetailRow(context, 'Total Amount', currencyFormat.format(debt.amount)),
                    _buildDetailRow(context, 'Amount Paid', currencyFormat.format(debt.payedAmount), isAmount: true, amountColor: Colors.green[700]),
                    if(debt.interest != null)
                      _buildDetailRow(context, 'Interest Paid', currencyFormat.format(debt.paidInterest), isAmount: true, amountColor: Colors.green[700]),
                    _buildDetailRow(context, 'Remaining', currencyFormat.format(debt.restAmount), isAmount: true, amountColor: debt.restAmount > 0 ? Colors.orange[700] : Colors.green[700]),
                    if (debt.amount > 0) 
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12, 
                                backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                              ),
                            ),
                        ),

                    if(debt.paymentModeTyped == model_debt.PaymentMode.installment)
                      _buildDetailRow(context, 'Payment Amount', currencyFormat.format(debt.paymentAmount)),

                    _buildDetailRow(context, 'First Paymentdate', dateFormat.format(debt.firstPaymentDate)),
                    _buildDetailRow(context, 'Status', debtStatusText, amountColor: statusColor),
                    _buildDetailRow(context, 'Category', debt.transaction?.category?.name),
                    _buildDetailRow(context, 'Initial Date', dateFormat.format(debt.firstPaymentDate)),

                    if(debt.dueDate != null)
                      _buildDetailRow(context, 'Due Date', dateFormat.format(debt.dueDate!)),

                    if(debt.paymentMethodTypisiert == model_debt.PaymentMethod.transfer)
                      _buildTransafertDetail(context, debt),

                    if(debt.paymentMethodTypisiert == model_debt.PaymentMethod.paypal)
                      _buildPayPalDetail(context, debt),

                  ],
                ),
              )
            ),
            SizedBox(height: 16),
            Card(
              elevation: Theme.of(context).cardTheme.elevation ?? 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payments (${debt.paymentRefs.length})', style: textTheme.titleLarge),
                        ElevatedButton.icon(
                          icon: Icon(Icons.add),
                          label: Text("Add Payment"),
                          onPressed: () {
                            showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => AddPaymentDialog(debt: debt, callback: (payment) {
                                  setState(() {
                                    debt.payments.add(payment);
                                  });
                                })
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    _buildPaymentsList(context, debt),
                  ]
                )
              )
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(Icons.notifications_active_outlined),
                label: Text("Schedule Test Notification"),
                style: ElevatedButton.styleFrom(backgroundColor: colorScheme.secondary),
                onPressed: () {
                  NotificationService().scheduleTestNotification(
                    id: debt.id.hashCode, // Use a unique ID, e.g., based on debt ID
                    title: 'Debt Reminder: ${debt.creditor}',
                    body: 'A test reminder for your debt: "${debt.creditor}". Due: ${debt.dueDate != null ? DateFormat.yMd().format(debt.dueDate!) : "N/A"}',
                    scheduledDateTime: DateTime.now().add(Duration(seconds: 5)),
                    payload: 'debt_${debt.id}'
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Test notification scheduled for 5 seconds from now.'), backgroundColor: Colors.blue)
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

      int _currentPage = 1;
    final int _itemsPerPage = 10;

    List<Payment> _paginatedPayments(model_debt.Debt debt) {
      return debt.payments.take(_currentPage * _itemsPerPage).toList();
    }

    bool _hasMorePayments(model_debt.Debt debt) {
      return _currentPage * _itemsPerPage < debt.payments.length;
    }

  Widget _buildPayPalDetail(BuildContext context, model_debt.Debt debt) {
    return Column(children: [
      _buildDetailRow(context, "PayPal E-Mail", debt.paypalEmail),
    ]);
  }

  Widget _buildTransafertDetail(BuildContext context, model_debt.Debt debt) {
    return Column(children: [
      _buildDetailRow(context, "IBAN", debt.iban),
      _buildDetailRow(context, "BIC", debt.bic),
      _buildDetailRow(context, "Accountholder", debt.bankAccountHolder),
      _buildDetailRow(context, "Purpose", debt.reason),
    ]);
  }

  Widget _buildPaymentsList(BuildContext context, model_debt.Debt debt) {
  final textTheme = Theme.of(context).textTheme;
  final colorScheme = Theme.of(context).colorScheme;

  final paymentsToShow = _paginatedPayments(debt);

  if (paymentsToShow.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(child: Text('No payments recorded yet.', style: textTheme.bodyMedium)),
    );
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: paymentsToShow.length,
        itemBuilder: (context, index) {
          final payment = paymentsToShow[index];
          return Card(
            elevation: 1.0,
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: Icon(Icons.payment, color: colorScheme.secondary),
              title: Text('${payment.amount} ${debt.currency ?? 'EUR'} : ${DateFormat('yyyy-MM').format(payment.date)}', style: textTheme.bodyMedium),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: colorScheme.error),
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Confirm Delete'),
                    content: Text('Are you sure you want to delete?'),
                    actions: [
                      TextButton(
                        child: Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      TextButton(
                        child: Text('Delete', style: TextStyle(color: colorScheme.error)),
                        onPressed: () {
                          context.read<DebtNotifier>().deletePaymentFromDebt(debt, payment, () {
                            setState(() {
                              debt.payments.remove(payment);
                            });
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      if (_hasMorePayments(debt))
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Center(
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _currentPage++;
                });
              },
              icon: Icon(Icons.expand_more),
              label: Text('Mehr laden'),
            ),
          ),
        ),
    ],
  );
}
}

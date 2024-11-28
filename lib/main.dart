import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'database.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Plan Tracking App',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _selectedDate = DateTime.now();
  double _targetValue = 0.0;
  List<FoodItem> _foodItems = [];
  List<FoodItem> _selectedFoods = [];
  double _priceTarget = 0.0;

  Set<DateTime> _budgetedDays = {}; // Dates with a budget set

  @override
  void initState() {
    super.initState();
    _loadBudgetedDays();
    _loadPriceTarget();
    _loadSelectedFoods();
  }

  Future<void> _loadBudgetedDays() async {
    final savedDates = await FoodDatabase.instance.fetchAllMealPlanDates();

    setState(() {
      _budgetedDays = savedDates.map((dateString) {
        return DateTime.parse(dateString);
      }).toSet();
    });
  }

  // Load price target for the selected date
  Future<void> _loadPriceTarget() async {
    final target = await FoodDatabase.instance.fetchPriceTargetForDate(
      DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    setState(() {
      _priceTarget = target ?? 0.0; // Reflect the saved value for the date
    });
  }

  // Load selected foods for the selected date
  Future<void> _loadSelectedFoods() async {
    final foods = await FoodDatabase.instance.fetchSelectedFoodsForDate(
      DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    setState(() {
      _selectedFoods = foods.map((item) {
        return FoodItem(
          name: item['name'],
          price: item['price'],
        );
      }).toList();
    });
  }

  // Save price target to the database
  Future<void> _saveTargetValue() async {
    await FoodDatabase.instance.insertOrUpdatePriceTarget(
      DateFormat('yyyy-MM-dd').format(_selectedDate),
      _targetValue,
    );
    setState(() {
      _priceTarget = _targetValue;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Price target saved for ${_selectedDate.toLocal()}')),
    );
  }

  // UI Layout (Build Method)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Plan Tracking App'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Interactive Calendar
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _selectedDate,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDate, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                  });
                  _loadPriceTarget(); // Reload target price for the selected day
                  _loadSelectedFoods(); // Reload selected foods
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    // Update focus without altering `_selectedDate`
                    _selectedDate = focusedDay;
                  });
                  _loadBudgetedDays(); // Reload budgeted days when changing pages
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_budgetedDays.contains(day)) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.green, // Green for budgeted days
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.all(6.0),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }
                    return null; // Default styling for other days
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.yellow, // Yellow for the selected day
                        shape: BoxShape.circle,
                      ),
                      margin: const EdgeInsets.all(6.0),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(color: Colors.black),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent, // Blue for today
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),


              const SizedBox(height: 20),
              // Selected Date and Target Price
              Text('Selected Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
              const SizedBox(height: 10),
              Text('Target Price: \$${_priceTarget.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              // Target price input field
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.75, // 3/4 of the screen width
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Enter Target Price',
                    prefixText: '\$', // Add a dollar sign prefix
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      _targetValue = double.tryParse(value) ?? 0.0; // Parse the input to a double
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              // Save price target button
              ElevatedButton(
                onPressed: _saveTargetValue,
                child: const Text('Save Price Target'),
              ),
              const SizedBox(height: 20),
              // Select food items button
              ElevatedButton(
                onPressed: () async {
                  await _loadPriceTarget(); // Ensure _priceTarget is up-to-date
                  _selectFoodItems(context); // Open the dialog
                },
                child: const Text('Select Food Items'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_targetValue > 0 && _selectedDate != null) {
                    // Prepare selected foods
                    final selectedFoodMaps = _selectedFoods.map((food) {
                      return {'name': food.name, 'price': food.price};
                    }).toList();

                    // Save the target price for the selected date
                    await FoodDatabase.instance.insertOrUpdatePriceTarget(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      _targetValue,
                    );

                    // Add the date to the budgeted days set
                    setState(() {
                      _budgetedDays.add(_selectedDate);
                    });

                    // Save the selected foods for the selected date
                    await FoodDatabase.instance.insertOrUpdateSelectedFoods(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                      selectedFoodMaps,
                    );

                    // Show confirmation message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meal plan saved!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select a date and target price!')),
                    );
                  }
                },
                child: const Text('Save Meal Plan'),
              ),
              const SizedBox(height: 20),
              // Show meal plan button
              ElevatedButton(
                onPressed: () => _showFoodListDialog(context),
                child: const Text('Show Meal Plan'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

                  // Check if there is data for the selected date
                  final targetPrice = await FoodDatabase.instance.fetchPriceTargetForDate(formattedDate);
                  final selectedFoods = await FoodDatabase.instance.fetchSelectedFoodsForDate(formattedDate);

                  if (targetPrice == null && selectedFoods.isEmpty) {
                    // Show a warning if there is no data to delete
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No meal plan found for the selected date.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Confirm deletion
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Delete Meal Plan'),
                        content: Text('Are you sure you want to delete the meal plan for $formattedDate?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false), // Cancel
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true), // Confirm
                            child: const Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    // Delete the meal plan for the selected date
                    await FoodDatabase.instance.deleteMealPlanForDate(formattedDate);

                    // Update the UI
                    setState(() {
                      _budgetedDays.remove(_selectedDate); // Remove the day from budgeted days
                      _priceTarget = 0.0;                  // Reset the target price
                      _selectedFoods.clear();              // Clear selected foods
                    });

                    // Show confirmation message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Meal plan deleted for $formattedDate')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Set the button's background color to red
                  foregroundColor: Colors.white, // Set the text color to white
                ),
                child: const Text('Delete Meal Plan'),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectFoodItems(BuildContext context) async {
    final foods = await FoodDatabase.instance.fetchFoods(); // Fetch food items from the database
    List<FoodItem> databaseFoods = foods.map((food) {
      return FoodItem(
        name: food['name'] as String,
        price: food['price'] as double,
      );
    }).toList();

    List<FoodItem> selectedFoods = List<FoodItem>.from(_selectedFoods);
    double currentTotal = selectedFoods.fold(0.0, (sum, item) => sum + item.price);

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Food Items'),
          content: SizedBox(
            width: double.maxFinite, // Ensure the dialog expands to fit its content
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Target Price, Current Total, Remaining Budget
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Target Price: \$${_priceTarget.toStringAsFixed(2)}'), // Use _priceTarget here
                        Text('Current Total: \$${currentTotal.toStringAsFixed(2)}'),
                        Text(
                          'Remaining: \$${(_priceTarget - currentTotal).toStringAsFixed(2)}', // Use _priceTarget here
                          style: TextStyle(
                            color: (_priceTarget - currentTotal) >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Food List (Scrollable)
                    Expanded(
                      child: ListView.builder(
                        itemCount: databaseFoods.length,
                        itemBuilder: (BuildContext context, int index) {
                          final food = databaseFoods[index];
                          return ListTile(
                            title: Text('${food.name} - \$${food.price.toStringAsFixed(2)}'),
                            trailing: Icon(
                              selectedFoods.contains(food)
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                              color: selectedFoods.contains(food) ? Colors.green : null,
                            ),
                            onTap: () {
                              setDialogState(() {
                                final newTotal = currentTotal + (selectedFoods.contains(food) ? -food.price : food.price);

                                if (!selectedFoods.contains(food) && newTotal > _targetValue) {
                                  // Show a warning if adding this item exceeds the budget
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Cannot add "${food.name}"! Total exceeds target price (\$${_targetValue.toStringAsFixed(2)})',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                if (selectedFoods.contains(food)) {
                                  selectedFoods.remove(food);
                                  currentTotal -= food.price;
                                } else {
                                  selectedFoods.add(food);
                                  currentTotal += food.price;
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFoods = selectedFoods;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }


  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });

      // Load the price target for the selected date
      final target = await FoodDatabase.instance.fetchPriceTargetForDate(
        DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      setState(() {
        _priceTarget = target ?? 0.0; // Use 0.0 if no target is saved
      });

      // Load the selected foods for the selected date
      _loadSelectedFoods();
    }
  }

  Future<void> _showFoodListDialog(BuildContext context) async {
    final date = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Fetch target price and selected foods for the selected date
    final targetPrice = await FoodDatabase.instance.fetchPriceTargetForDate(date);
    final selectedFoods = await FoodDatabase.instance.fetchSelectedFoodsForDate(date);

    if (targetPrice == null && selectedFoods.isEmpty) {
      // If no data is saved for this date
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No meal plan saved for $date')),
      );
      return;
    }

    // Show the meal plan in a dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Meal Plan for $date'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Target Price: \$${targetPrice?.toStringAsFixed(2) ?? "N/A"}'),
              Text(
                  'Total Price: \$${selectedFoods.fold(0.0, (sum, item) => sum + (item['price'] as double)).toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              const Text('Selected Foods:'),
              ...selectedFoods.map((food) {
                return Text('${food['name']} - \$${(food['price'] as double).toStringAsFixed(2)}');
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Represents a food item
class FoodItem {
  final String name;
  final double price;

  FoodItem({required this.name, required this.price});

  // Override == operator to compare objects by value
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FoodItem &&
        other.name == name &&
        other.price == price;
  }

  // Override hashCode to match the == operator
  @override
  int get hashCode => name.hashCode ^ price.hashCode;
}
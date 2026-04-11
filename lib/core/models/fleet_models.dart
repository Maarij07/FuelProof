import 'package:json_annotation/json_annotation.dart';

part 'fleet_models.g.dart';

// ============================================================================
// VEHICLE MODEL
// ============================================================================

@JsonSerializable()
class Vehicle {
  final String id;

  @JsonKey(name: 'registration_number')
  final String registrationNumber;

  final String make;

  final String model;

  final int year;

  @JsonKey(name: 'fuel_type')
  final String fuelType;

  @JsonKey(name: 'tank_capacity')
  final double tankCapacity;

  @JsonKey(name: 'owner_uid')
  final String ownerUid;

  @JsonKey(name: 'assigned_driver_uid')
  final String? assignedDriverUid;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'total_fuel_consumed')
  final double totalFuelConsumed;

  @JsonKey(name: 'total_expense')
  final double totalExpense;

  @JsonKey(name: 'created_at')
  final String createdAt;

  Vehicle({
    required this.id,
    required this.registrationNumber,
    required this.make,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.tankCapacity,
    required this.ownerUid,
    this.assignedDriverUid,
    required this.isActive,
    required this.totalFuelConsumed,
    required this.totalExpense,
    required this.createdAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);
}

// ============================================================================
// VEHICLE CONSUMPTION MODEL
// ============================================================================

@JsonSerializable()
class VehicleConsumption {
  @JsonKey(name: 'vehicle_id')
  final String vehicleId;

  @JsonKey(name: 'registration_number')
  final String registrationNumber;

  @JsonKey(name: 'total_fuel_consumed')
  final double totalFuelConsumed;

  @JsonKey(name: 'monthly_breakdown')
  final Map<String, MonthlyBreakdown> monthlyBreakdown;

  VehicleConsumption({
    required this.vehicleId,
    required this.registrationNumber,
    required this.totalFuelConsumed,
    required this.monthlyBreakdown,
  });

  factory VehicleConsumption.fromJson(Map<String, dynamic> json) =>
      _$VehicleConsumptionFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleConsumptionToJson(this);
}

@JsonSerializable()
class MonthlyBreakdown {
  final double litres;

  final double amount;

  MonthlyBreakdown({required this.litres, required this.amount});

  factory MonthlyBreakdown.fromJson(Map<String, dynamic> json) =>
      _$MonthlyBreakdownFromJson(json);

  Map<String, dynamic> toJson() => _$MonthlyBreakdownToJson(this);
}

// ============================================================================
// EXPENSE ENUMS & MODELS
// ============================================================================

enum ExpenseCategory {
  @JsonValue('fuel')
  fuel,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('toll')
  toll,
  @JsonValue('parking')
  parking,
  @JsonValue('other')
  other,
}

@JsonSerializable()
class Expense {
  final String id;

  @JsonKey(name: 'vehicle_id')
  final String vehicleId;

  @JsonKey(name: 'user_id')
  final String userId;

  final ExpenseCategory category;

  final double amount;

  final double? litres;

  @JsonKey(name: 'station_id')
  final String? stationId;

  final String? description;

  @JsonKey(name: 'expense_date')
  final String expenseDate;

  @JsonKey(name: 'created_at')
  final String createdAt;

  Expense({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.category,
    required this.amount,
    this.litres,
    this.stationId,
    this.description,
    required this.expenseDate,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseToJson(this);
}

@JsonSerializable()
class ExpenseListResponse {
  final int total;

  final List<Expense> items;

  ExpenseListResponse({required this.total, required this.items});

  factory ExpenseListResponse.fromJson(Map<String, dynamic> json) =>
      _$ExpenseListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseListResponseToJson(this);
}

// ============================================================================
// BUDGET MODEL
// ============================================================================

@JsonSerializable()
class Budget {
  final String id;

  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'vehicle_id')
  final String? vehicleId;

  final int month;

  final int year;

  @JsonKey(name: 'budget_amount')
  final double budgetAmount;

  @JsonKey(name: 'spent_amount')
  final double spentAmount;

  final double remaining;

  Budget({
    required this.id,
    required this.userId,
    this.vehicleId,
    required this.month,
    required this.year,
    required this.budgetAmount,
    required this.spentAmount,
    required this.remaining,
  });

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  Map<String, dynamic> toJson() => _$BudgetToJson(this);
}

// ============================================================================
// DRIVER MODEL
// ============================================================================

@JsonSerializable()
class Driver {
  final String id;

  @JsonKey(name: 'full_name')
  final String fullName;

  final String phone;

  @JsonKey(name: 'license_number')
  final String licenseNumber;

  final String? uid;

  @JsonKey(name: 'assigned_vehicle_id')
  final String? assignedVehicleId;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'created_at')
  final String createdAt;

  Driver({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.licenseNumber,
    this.uid,
    this.assignedVehicleId,
    required this.isActive,
    required this.createdAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => _$DriverFromJson(json);

  Map<String, dynamic> toJson() => _$DriverToJson(this);
}

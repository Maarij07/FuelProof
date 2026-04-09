// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleet_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
      id: json['id'] as String,
      registrationNumber: json['registration_number'] as String,
      make: json['make'] as String,
      model: json['model'] as String,
      year: (json['year'] as num).toInt(),
      fuelType: json['fuel_type'] as String,
      tankCapacity: (json['tank_capacity'] as num).toDouble(),
      ownerUid: json['owner_uid'] as String,
      assignedDriverUid: json['assigned_driver_uid'] as String?,
      isActive: json['is_active'] as bool,
      totalFuelConsumed: (json['total_fuel_consumed'] as num).toDouble(),
      totalExpense: (json['total_expense'] as num).toDouble(),
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
      'id': instance.id,
      'registration_number': instance.registrationNumber,
      'make': instance.make,
      'model': instance.model,
      'year': instance.year,
      'fuel_type': instance.fuelType,
      'tank_capacity': instance.tankCapacity,
      'owner_uid': instance.ownerUid,
      'assigned_driver_uid': instance.assignedDriverUid,
      'is_active': instance.isActive,
      'total_fuel_consumed': instance.totalFuelConsumed,
      'total_expense': instance.totalExpense,
      'created_at': instance.createdAt,
    };

VehicleConsumption _$VehicleConsumptionFromJson(Map<String, dynamic> json) =>
    VehicleConsumption(
      vehicleId: json['vehicle_id'] as String,
      registrationNumber: json['registration_number'] as String,
      totalFuelConsumed: (json['total_fuel_consumed'] as num).toDouble(),
      monthlyBreakdown: (json['monthly_breakdown'] as Map<String, dynamic>).map(
        (k, e) =>
            MapEntry(k, MonthlyBreakdown.fromJson(e as Map<String, dynamic>)),
      ),
    );

Map<String, dynamic> _$VehicleConsumptionToJson(VehicleConsumption instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'registration_number': instance.registrationNumber,
      'total_fuel_consumed': instance.totalFuelConsumed,
      'monthly_breakdown': instance.monthlyBreakdown,
    };

MonthlyBreakdown _$MonthlyBreakdownFromJson(Map<String, dynamic> json) =>
    MonthlyBreakdown(
      litres: (json['litres'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$MonthlyBreakdownToJson(MonthlyBreakdown instance) =>
    <String, dynamic>{
      'litres': instance.litres,
      'amount': instance.amount,
    };

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      userId: json['user_id'] as String,
      category: $enumDecode(_$ExpenseCategoryEnumMap, json['category']),
      amount: (json['amount'] as num).toDouble(),
      litres: (json['litres'] as num?)?.toDouble(),
      stationId: json['station_id'] as String?,
      description: json['description'] as String?,
      expenseDate: json['expense_date'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'user_id': instance.userId,
      'category': _$ExpenseCategoryEnumMap[instance.category]!,
      'amount': instance.amount,
      'litres': instance.litres,
      'station_id': instance.stationId,
      'description': instance.description,
      'expense_date': instance.expenseDate,
      'created_at': instance.createdAt,
    };

const _$ExpenseCategoryEnumMap = {
  ExpenseCategory.fuel: 'fuel',
  ExpenseCategory.maintenance: 'maintenance',
  ExpenseCategory.toll: 'toll',
  ExpenseCategory.parking: 'parking',
  ExpenseCategory.other: 'other',
};

ExpenseListResponse _$ExpenseListResponseFromJson(Map<String, dynamic> json) =>
    ExpenseListResponse(
      total: (json['total'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ExpenseListResponseToJson(
        ExpenseListResponse instance) =>
    <String, dynamic>{
      'total': instance.total,
      'items': instance.items,
    };

Budget _$BudgetFromJson(Map<String, dynamic> json) => Budget(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleId: json['vehicle_id'] as String?,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      budgetAmount: (json['budget_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
    );

Map<String, dynamic> _$BudgetToJson(Budget instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'vehicle_id': instance.vehicleId,
      'month': instance.month,
      'year': instance.year,
      'budget_amount': instance.budgetAmount,
      'spent_amount': instance.spentAmount,
      'remaining': instance.remaining,
    };

Driver _$DriverFromJson(Map<String, dynamic> json) => Driver(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      licenseNumber: json['license_number'] as String,
      uid: json['uid'] as String?,
      assignedVehicleId: json['assigned_vehicle_id'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$DriverToJson(Driver instance) => <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'phone': instance.phone,
      'license_number': instance.licenseNumber,
      'uid': instance.uid,
      'assigned_vehicle_id': instance.assignedVehicleId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt,
    };

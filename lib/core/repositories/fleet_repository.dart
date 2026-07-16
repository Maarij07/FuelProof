import '../models/fleet_models.dart';
import '../models/error_models.dart';
import '../services/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODULE DISCONNECTED: Fleet management APIs are outside FYP scope (Modules
// 1-3). All API calls are commented out. To reconnect, remove the stub returns
// and un-comment the try/catch blocks inside each method.
// ─────────────────────────────────────────────────────────────────────────────

class FleetRepository {
  final ApiClient apiClient;

  FleetRepository({required this.apiClient});

  /// Get all vehicles for current user
  Future<List<Vehicle>> getVehicles() async {
    // TODO: reconnect when Fleet module is in scope
    return [];

    // try {
    //   final response = await apiClient.get<List<dynamic>>('/fleet/vehicles');
    //
    //   return response
    //       .map((item) => Vehicle.fromJson(item as Map<String, dynamic>))
    //       .toList();
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Add new vehicle
  Future<Vehicle> addVehicle({
    required String registrationNumber,
    required String make,
    required String model,
    required int year,
    required String fuelType,
    required double tankCapacity,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final response = await apiClient.post<Map<String, dynamic>>(
    //     '/fleet/vehicles',
    //     data: {
    //       'registration_number': registrationNumber,
    //       'make': make,
    //       'model': model,
    //       'year': year,
    //       'fuel_type': fuelType,
    //       'tank_capacity': tankCapacity,
    //     },
    //   );
    //
    //   return Vehicle.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Get specific vehicle details
  Future<Vehicle> getVehicle(String vehicleId) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final response = await apiClient.get<Map<String, dynamic>>(
    //     '/fleet/vehicles/$vehicleId',
    //   );
    //
    //   return Vehicle.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Update vehicle
  Future<Vehicle> updateVehicle({
    required String vehicleId,
    String? make,
    String? model,
    String? fuelType,
    double? tankCapacity,
    bool? isActive,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final data = <String, dynamic>{};
    //   if (make != null) data['make'] = make;
    //   if (model != null) data['model'] = model;
    //   if (fuelType != null) data['fuel_type'] = fuelType;
    //   if (tankCapacity != null) data['tank_capacity'] = tankCapacity;
    //   if (isActive != null) data['is_active'] = isActive;
    //
    //   final response = await apiClient.put<Map<String, dynamic>>(
    //     '/fleet/vehicles/$vehicleId',
    //     data: data,
    //   );
    //
    //   return Vehicle.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Delete vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    // TODO: reconnect when Fleet module is in scope
    return;

    // try {
    //   await apiClient.delete('/fleet/vehicles/$vehicleId');
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Get vehicle consumption data
  Future<VehicleConsumption> getVehicleConsumption(String vehicleId) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final response = await apiClient.get<Map<String, dynamic>>(
    //     '/fleet/vehicles/$vehicleId/consumption',
    //   );
    //
    //   return VehicleConsumption.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Get expenses for vehicle
  Future<ExpenseListResponse> getExpenses({
    required String vehicleId,
    String? category,
    int? month,
    int? year,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final queryParams = <String, dynamic>{'vehicle_id': vehicleId};
    //   if (category != null) queryParams['category'] = category;
    //   if (month != null) queryParams['month'] = month;
    //   if (year != null) queryParams['year'] = year;
    //
    //   final response = await apiClient.get<Map<String, dynamic>>(
    //     '/fleet/expenses',
    //     queryParameters: queryParams,
    //   );
    //
    //   return ExpenseListResponse.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Log new expense
  Future<Expense> logExpense({
    required String vehicleId,
    required ExpenseCategory category,
    required double amount,
    double? litres,
    String? stationId,
    String? description,
    String? expenseDate,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final data = <String, dynamic>{
    //     'vehicle_id': vehicleId,
    //     'category': category.toString().split('.').last,
    //     'amount': amount,
    //   };
    //   if (litres != null) data['litres'] = litres;
    //   if (stationId != null) data['station_id'] = stationId;
    //   if (description != null) data['description'] = description;
    //   if (expenseDate != null) data['expense_date'] = expenseDate;
    //
    //   final response = await apiClient.post<Map<String, dynamic>>(
    //     '/fleet/expenses',
    //     data: data,
    //   );
    //
    //   return Expense.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Get budget
  Future<Budget> getBudget({
    required String vehicleId,
    required int month,
    required int year,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final response = await apiClient.get<Map<String, dynamic>>(
    //     '/fleet/budget',
    //     queryParameters: {
    //       'vehicle_id': vehicleId,
    //       'month': month,
    //       'year': year,
    //     },
    //   );
    //
    //   return Budget.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Set or update budget
  Future<void> setBudget({
    required String? vehicleId,
    required int month,
    required int year,
    required double amount,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    return;

    // try {
    //   await apiClient.put(
    //     '/fleet/budget',
    //     data: {
    //       'vehicle_id': vehicleId,
    //       'month': month,
    //       'year': year,
    //       'amount': amount,
    //     },
    //   );
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Get all drivers
  Future<List<Driver>> getDrivers() async {
    // TODO: reconnect when Fleet module is in scope
    return [];

    // try {
    //   final response = await apiClient.get<List<dynamic>>('/fleet/drivers');
    //
    //   return response
    //       .map((item) => Driver.fromJson(item as Map<String, dynamic>))
    //       .toList();
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Add new driver
  Future<Driver> addDriver({
    required String fullName,
    required String phone,
    required String licenseNumber,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    throw AppError(message: 'Fleet module not connected');

    // try {
    //   final response = await apiClient.post<Map<String, dynamic>>(
    //     '/fleet/drivers',
    //     data: {
    //       'full_name': fullName,
    //       'phone': phone,
    //       'license_number': licenseNumber,
    //     },
    //   );
    //
    //   return Driver.fromJson(response);
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  /// Assign driver to vehicle
  Future<void> assignDriver({
    required String vehicleId,
    required String driverUid,
  }) async {
    // TODO: reconnect when Fleet module is in scope
    return;

    // try {
    //   await apiClient.put(
    //     '/fleet/vehicles/$vehicleId/driver',
    //     data: {'driver_uid': driverUid},
    //   );
    // } catch (e) {
    //   throw _handleError(e);
    // }
  }

  // ignore: unused_element
  AppError _handleError(dynamic error) {
    if (error is AppError) return error;
    return AppError(message: 'An unexpected error occurred');
  }
}

import 'package:flutter/material.dart';
import '../features/dashboard/main_shell_page.dart';
import '../features/bookings/booking_details_page.dart';
import '../features/bookings/create_booking_page.dart';
import '../features/trips/edit_trip_page.dart';
import '../features/trips/create_trip_page.dart';
import '../features/expenses/trip_expense_ledger_page.dart';
import '../features/profile/profile_page.dart';
import '../features/trips/trip_bookings_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/auth/forgot_password_page.dart';
import '../features/auth/reset_password_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  static const String dashboard = '/';
  static const String selectTrip = '/select-trip';
  static const String createBooking = '/create-booking';
  static const String bookingDetails = '/booking-details';
  static const String manageBookings = '/manage-bookings';
  static const String profile = '/profile';
  static const String enquiries = '/enquiries';
  static const String editTrip = '/edit-trip';
  static const String createTrip = '/create-trip';
  static const String expenses = '/expenses';
  static const String tripExpenseLedger = '/trip-expense-ledger';
  static const String customers = '/customers';
  static const String tripBookings = '/trip-bookings';

  static Map<String, WidgetBuilder> get routes => {
    login: (context) => const LoginPage(),
    signup: (context) => const SignupPage(),
    forgotPassword: (context) => const ForgotPasswordPage(),
    resetPassword: (context) => const ResetPasswordPage(),

    dashboard: (context) => const MainShellPage(initialIndex: 0),
    selectTrip: (context) => const MainShellPage(initialIndex: 1),
    createBooking: (context) => const CreateBookingPage(),
    bookingDetails: (context) => const BookingDetailsPage(),
    manageBookings: (context) => const MainShellPage(initialIndex: 2),
    profile: (context) => const ProfilePage(),
    enquiries: (context) => const MainShellPage(initialIndex: 3),
    editTrip: (context) => const EditTripPage(),
    createTrip: (context) => const CreateTripPage(),
    expenses: (context) => const MainShellPage(initialIndex: 3),
    tripExpenseLedger: (context) => const TripExpenseLedgerPage(),
    customers: (context) => const MainShellPage(initialIndex: 3),
    tripBookings: (context) => const TripBookingsPage(),
  };
}

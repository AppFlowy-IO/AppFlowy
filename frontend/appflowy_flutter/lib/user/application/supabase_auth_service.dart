import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class SupabaseAuthService {
  const SupabaseAuthService();

  Future<Either<Error, User>> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      // TODO: handle error
      return left(Error());
    }
    return Right(user);
  }

  Future<Either<Error, User>> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      // TODO: handle error
      return left(Error());
    }
    return Right(user);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _supabase.auth.currentUser;
  }
}

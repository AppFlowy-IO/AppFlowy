import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  const SupabaseAuthService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  Future<Either<Error, User>> signUp(String email, String password) async {
    await _auth.signInWithOAuth(Provider.google);
    final response = await _auth.signUp(
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
    await _auth.signInWithOAuth(Provider.google);
    final response = await _auth.signInWithPassword(
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
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
}

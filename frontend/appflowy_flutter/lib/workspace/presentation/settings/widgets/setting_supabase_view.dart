import 'package:appflowy/workspace/application/settings/setting_supabase_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupabaseSettingView extends StatelessWidget {
  const SupabaseSettingView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SettingSupabaseBloc()..add(const SettingSupabaseEvent.initial()),
      child: BlocBuilder<SettingSupabaseBloc, SettingSupabaseState>(
        builder: (context, state) {
          return Align(
            alignment: Alignment.topRight,
            child: Switch(
              onChanged: (bool value) {
                context.read<SettingSupabaseBloc>().add(
                      SettingSupabaseEvent.enableSync(value),
                    );
              },
              value: state.config?.enableSync ?? false,
            ),
          );
        },
      ),
    );
  }
}

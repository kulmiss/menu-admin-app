import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/cache/swr.dart';
import '../../core/providers.dart';
import '../../core/util/links.dart';
import '../../core/widgets/kit.dart';
import '../../core/widgets/paged_list.dart';

IconData notificationIcon(String type) => switch (type) {
  'plan_expiring' || 'plan_expired' => Icons.event_busy_outlined,
  'monthly_report' => Icons.insights_outlined,
  'invitation_accepted' => Icons.group_add_outlined,
  'platform_announcement' => Icons.campaign_outlined,
  'signup_new' || 'signup_pending' => Icons.storefront_outlined,
  'payment_recorded' => Icons.payments_outlined,
  'backup_failed' => Icons.backup_outlined,
  'health_warning' => Icons.monitor_heart_outlined,
  'followups_due' => Icons.event_note_outlined,
  _ => Icons.notifications_outlined,
};

/// The notification inbox (last 90 days, from the server).
class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.inbox),
        actions: [
          TextButton(
            onPressed: () async {
              await runOk(context, () => ref.read(apiProvider).post('mobile/notifications/read', data: {'all': true}));
              ref.invalidate(cachedProvider('mobile/notifications'));
            },
            child: Text(l.markAllRead),
          ),
        ],
      ),
      body: PagedList(
        path: 'mobile/notifications',
        cursor: true,
        empty: EmptyState(icon: Icons.notifications_none, title: l.inboxEmpty),
        itemBuilder: (context, n, _) => ListTile(
          leading: Icon(notificationIcon(n.s('type')), color: n.b('read') ? context.colors.onSurfaceVariant : context.colors.primary),
          title: Text(n.s('title'), style: TextStyle(fontWeight: n.b('read') ? FontWeight.w400 : FontWeight.w600)),
          subtitle: Text('${n.s('body')}\n${formatDate(context, n.sn('created_at'), time: true)}'),
          isThreeLine: true,
          onTap: () {
            ref
                .read(apiProvider)
                .post(
                  'mobile/notifications/read',
                  data: {
                    'ids': [n.i('id')],
                  },
                )
                .ignore();
            final path = appPathFrom(n.s('link'));
            if (path != null) context.push(path);
          },
        ),
      ),
    );
  }
}

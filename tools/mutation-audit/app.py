"""Mutation audit for the Flutter side."""
import io
import re
import subprocess

ROOT = 'D:/Jakuan/Projects/Telemedicine/bienify-app'

MUTATIONS = [
    ('courier peer carries no thread',
     'lib/features/Role/rider_role/presentation/controllers/rider_orders_controller.dart',
     "        thread: ChatThread.delivery(job.request.id),\n",
     "",
     'test/features/courier_chat_test.dart'),

    ('courier peer identified by the delivery, not the customer',
     'lib/features/Role/rider_role/presentation/controllers/rider_orders_controller.dart',
     "        id: job.request.customerId,",
     "        id: job.request.id,",
     'test/features/courier_chat_test.dart'),

    ('rider opens a chat with no job',
     'lib/features/Role/rider_role/presentation/controllers/rider_orders_controller.dart',
     "    if (job == null) {\n      AppSnackbar.info(AppStrings.noActiveDelivery.tr);\n      return;\n    }\n",
     "    if (job == null) return;\n",
     'test/features/courier_chat_test.dart'),

    ('thread kind ignored when reading a payload',
     'lib/core/models/chat_thread.dart',
     "    final delivery = '${json['deliveryId'] ?? ''}';\n    if (delivery.isNotEmpty) return ChatThread.delivery(delivery);\n",
     "",
     'test/features/courier_chat_test.dart'),

    ('two threads sharing an id compare equal',
     'lib/core/models/chat_thread.dart',
     "      other is ChatThread && other.kind == kind && other.id == id;",
     "      other is ChatThread && other.id == id;",
     'test/features/courier_chat_test.dart'),

    ('delivery payload names the wrong field',
     'lib/core/models/chat_thread.dart',
     "      isConsultation ? {'appointmentId': id} : {'deliveryId': id};",
     "      {'appointmentId': id};",
     'test/features/courier_chat_test.dart'),

    ('an empty thread counts as live',
     'lib/core/models/chat_thread.dart',
     "  bool get isLive => id.isNotEmpty;",
     "  bool get isLive => true;",
     'test/features/courier_chat_test.dart'),

    # ── the saved delivery address ─────────────────────────────────────────
    ('checkout saves every edit to the profile',
     'lib/features/Role/patient/pharmacy/presentation/controllers/pharmacy_cart_controller.dart',
     "    if (!saveToProfile) return;\n",
     "",
     'test/golden/pharmacy_golden_test.dart'),

    ('order placed with a blank address',
     'lib/features/Role/patient/pharmacy/presentation/controllers/pharmacy_cart_controller.dart',
     "    if (!address.value.isComplete) {",
     "    if (false) {",
     'test/features/pharmacy_checkout_test.dart'),

    ('address dialog accepts an empty street',
     'lib/features/Role/patient/pharmacy/presentation/widgets/location_dialog.dart',
     "    if (line1.isEmpty) {\n      setState(() => _line1Error = AppStrings.streetRequired.tr);\n      return;\n    }\n",
     "",
     'test/golden/pharmacy_golden_test.dart'),

    # ── doctor standing on the card ────────────────────────────────────────
    ('patients-consulted never mapped',
     'lib/core/network/mappers.dart',
     "  patientsSeen: Api.integer(json['patientsSeen']),",
     "  patientsSeen: 0,",
     'test/features/doctor_standing_test.dart'),
]


def run(suite):
    r = subprocess.run(['flutter', 'test', suite, '-r', 'expanded'],
                       cwd=ROOT, capture_output=True, shell=True)
    out = (r.stdout or b'').decode('utf-8', 'replace') + (r.stderr or b'').decode('utf-8', 'replace')
    reds = re.findall(r'\+\d+ -\d+: (.+?) \[E\]', out)
    passed = 'All tests passed!' in out
    return (0 if passed else max(1, len(set(reds)))), sorted(set(reds))


print('Baseline\n')
for suite in sorted({m[4] for m in MUTATIONS}):
    failed, _ = run(suite)
    print(f'  {suite:46} {"GREEN" if failed == 0 else f"ALREADY RED ({failed})"}')

print('\nMutations:\n')
survivors = []
for label, rel, find, repl, suite in MUTATIONS:
    path = f'{ROOT}/{rel}'
    original = io.open(path, encoding='utf-8').read()
    if find not in original:
        print(f'  SKIP      {label}\n            (anchor not found in {rel})')
        survivors.append((label, 'anchor not found'))
        continue
    io.open(path, 'w', encoding='utf-8').write(original.replace(find, repl, 1))
    try:
        failed, names = run(suite)
    finally:
        io.open(path, 'w', encoding='utf-8').write(original)

    if failed > 0:
        print(f'  CAUGHT    {label}\n            e.g. "{names[0] if names else "compile/assert failure"}"')
    else:
        print(f'  SURVIVED  {label}  <-- nothing tests this')
        survivors.append((label, 'no test failed'))

print('\n' + '=' * 70)
if survivors:
    print(f'{len(survivors)} survived:')
    for label, why in survivors:
        print(f'  - {label} ({why})')
else:
    print(f'All {len(MUTATIONS)} mutations caught.')

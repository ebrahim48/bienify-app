Hi Arlyne,

The payment screens in the app are fully built — card, Apple/Google Pay, bank
transfer, TPAGO, PayPal and cash-at-location are all there, along with the
wallet, balances and receipts. Right now they run in test mode, which means a
payment always "succeeds" but no real money moves.

To switch them on for real money, I need account details from you. I've listed
everything below, but **the most important thing is question 1** — your answer
to that decides what else is needed.

## 1. Which payment processor do you have a merchant account with?

This is the key one. Card payments have to go through a licensed processor, and
which ones you can use depends on the country the business is registered in.
Since the app includes TPAGO, I'm assuming the Dominican Republic — in which
case the usual options are **Azul**, **CardNet**, or **PayPal**. (Stripe, the
most common one worldwide, does not serve merchants in every country, so I need
to know before I build against it.)

Please tell me:

- The country your business/company is registered in
- Whether you already have a merchant account, and with whom
- If you don't have one yet, whether you'd like me to recommend one

Everything below depends on this answer, so feel free to reply with just this
part first.

## 2. Card payments (and Apple/Google Pay)

Once you have a merchant account, I'll need from that provider's dashboard:

- **Test/sandbox keys** — a public key and a secret key
- **Live keys** — the same pair, for real payments
- **Webhook secret** — lets the app confirm a payment truly succeeded, rather
  than trusting the phone

Apple Pay and Google Pay ride on top of the same card processor, so no separate
payment account is needed. Apple Pay additionally needs your **Apple Developer
account** (Team ID and a merchant identifier) — this is the same account the app
is published under.

## 3. PayPal

From the PayPal Developer dashboard:

- **Client ID** and **Secret** for sandbox (testing)
- **Client ID** and **Secret** for live
- The PayPal business email that should receive the money

## 4. TPAGO

TPAGO requires enrolment as a merchant. I'll need whatever credentials they
issue you (usually a merchant ID and an API key or certificate), plus any
integration documentation they provide, since their setup differs from the
international providers.

## 5. Bank transfer

This one is manual rather than automated. I need:

- Bank name, account name and account number
- Any reference format you want patients to use
- Who checks the bank account and marks a payment as received, and how you'd
  like that to work

## 6. Cash at location

Already built and working. Patients get a code and take it to a payment point. I
just need to know: who confirms that the cash was collected, and should that be
done from an admin screen? (There's currently no admin app, so this step has no
home yet — worth discussing.)

## How to send these safely

Please **don't paste live secret keys into Fiverr chat or email** — anyone who
sees them can take payments in your name.

The safest options, easiest first:

1. Add me as a **team member with developer/API access** on each dashboard
   (PayPal, your card processor). Then I never handle your secrets at all, and
   you can remove my access whenever you like. This is what I'd recommend.
2. Send them through a one-time secret link — **onetimesecret.com** is free and
   needs no account. The link self-destructs after I open it.

Sandbox/test keys are not sensitive, so those are fine to send normally.

## Suggested order

We don't need everything at once. If you send me the **test/sandbox
credentials** for one method first — usually card or PayPal — I can wire it up
end to end, show you a working payment, and then repeat for the rest. Live keys
only need to come last, once you've seen it working.

## One thing to be aware of

Payments will require a real account in your business's name, with the
provider's verification (business documents, bank account, sometimes a few days'
review). That approval time is outside my control, so it's worth starting the
merchant account application early even before we wire anything up.

Just reply with question 1 to start, and I'll take it from there.

Thanks,

# QA Checklist (StajyerPro)

- [ ] Auth flow: splash -> onboarding -> login/register -> dashboard redirect works.
- [ ] Subscription gating: free limits block extra quiz (per day), AI chat (per day), exam (per month); pro bypasses.
- [ ] Paywall buttons: upgrade/restore placeholders open and return without crash.
- [ ] Quiz flow: select topics -> start -> answer -> result -> retry/continue to dashboard.
- [ ] Exam flow: start deneme -> gating check -> finish -> result analytics display.
- [ ] AI coach: message send/receive, limit warning on free plan.
- [ ] Notifications: study plan reminder toggle and time picker update without error.
- [ ] Admin panel: accessible only to admin flag; seed subjects/topics/questions writes without duplicates.
- [ ] Analytics screen: loads stats/graphs without exceptions.
- [ ] App router: 404 screen renders and home/back navigation returns to dashboard.

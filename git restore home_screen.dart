[1mdiff --git a/flutter_application_1/lib/screens/home_screen.dart b/flutter_application_1/lib/screens/home_screen.dart[m
[1mindex 284c538..53ef96e 100644[m
[1m--- a/flutter_application_1/lib/screens/home_screen.dart[m
[1m+++ b/flutter_application_1/lib/screens/home_screen.dart[m
[36m@@ -155,38 +155,88 @@[m [mclass HomeScreen extends StatelessWidget {[m
                 ),[m
               ),[m
 [m
[31m-              // ─── Main Feed Cards ───[m
[32m+[m[32m              // ─── The Mosaic Feed (✨ For You) ───[m
               SliverPadding([m
                 padding: const EdgeInsets.symmetric(horizontal: 16),[m
[31m-                sliver: SliverList([m
[31m-                  delegate: SliverChildListDelegate([[m
[31m-                    const FeedCard(title: "Cozy Study Timer", tag: "cozy", type: "pomodoro"),[m
[31m-                    const FeedCard(title: "Daily Quote", tag: "quote", type: "quote"),[m
[31m-                    const FeedCard(title: "Personal Notepad", tag: "notes", type: "notepad"),[m
[31m-                    const FeedCard(title: "Aesthetic Calendar", tag: "minimal", type: "calendar"),[m
[31m-                    const FeedCard(title: "Habit Tracker", tag: "personal", type: "habit"),[m
[31m-                    const FeedCard(title: "Mood Tracker", tag: "wellbeing", type: "mood"),[m
[31m-                  ]),[m
[31m-                ),[m
[31m-              ),[m
[31m-[m
[31m-[m
[32m+[m[32m                sliver: SliverGrid([m
[32m+[m[32m                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount([m
[32m+[m[32m                    crossAxisCount: 2,[m
[32m+[m[32m                    mainAxisSpacing: 16,[m
[32m+[m[32m                    crossAxisSpacing: 16,[m
[32m+[m[32m                    childAspectRatio: 0.82,[m
[32m+[m[32m                  ),[m
[32m+[m[32m                  delegate: SliverChildBuilderDelegate([m
[32m+[m[32m                    (context, index) {[m
[32m+[m[32m                      final items = const [[m
[32m+[m[32m                        FeedCard([m
[32m+[m[32m                          title: "Cozy Study Timer",[m
[32m+[m[32m                          tag: "cozy",[m
[32m+[m[32m                          type: "pomodoro",[m
[32m+[m[32m                        ),[m
[32m+[m[32m                        FeedCard([m
[32m+[m[32m                          title: "Daily Quote",[m
[32m+[m[32m                          tag: "quote",[m
[32m+[m[32m                          type: "quote",[m
[32m+[m[32m                        ),[m
[32m+[m[32m                        FeedCard([m
[32m+[m[32m                          title: "Personal Notepad",[m
[32m+[m[32m                          tag: "notes",[m
[32m+[m[32m                          type: "notepad",[m
[32m+[m[32m                        ),[m
[32m+[m[32m                        FeedCard([m
[32m+[m[32m                          title: "Aesthetic Calendar",[m
[32m+[m[32m                          tag: "minimal",[m
[32m+[m[32m                          type: "calendar",[m
[32m+[m[32m                        ),[m
[32m+[m[32m                        FeedCard([m
[32m+[m[32m                          title: "Habit Tracker",[m
[32m+[m[32m                          tag: "personal",[m
[32m+[m[32m                          type: "habit",[m
[32m+[m[32m                        ),[m
[32m+[m[32m                        FeedCard([m
[32m+[m[32m                          title: "Mood Tracker",[m
[32m+[m[32m                          tag: "wellbeing",[m
[32m+[m[32m                          type: "mood",[m
[32m+[m[32m                        ),[m
[32m+[m[32m                        FeedCard([m
[32m+[m[32m                          title: "Day Progress",[m
[32m+[m[32m                          tag: "minimal",[m
[32m+[m[32m                          type: "day_progress",[m
[32m+[m[32m                        ),[m
[32m+[m[32m      
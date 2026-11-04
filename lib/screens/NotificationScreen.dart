import 'package:monteage_employee/utils/constants/color_constants.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart'; // Import the intl package for date formatting
import '../controllers/NotificationController.dart';
import '../widgets/bottom_nav_wrapper.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return BottomNavWrapper(
      child: Scaffold(
        backgroundColor: Colors.white, // Always white for background (no theme toggle here)
        appBar: AppBar(
          elevation: 5,
          iconTheme: const IconThemeData(color: Colors.white),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColor.accent, // Red Violet
                  AppColor.primaryDark, // Oxblood
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: controller.isSearching.value
              ? TextField(
            onChanged: (query) {
              controller.filterNotifications(query); // Update the search query
            },
            decoration: InputDecoration(
              hintText: 'Search Notifications...',
              hintStyle: TextStyle(color: Colors.white),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.white),
            ),
          )
              : const Text(
            "Notifications",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                controller.isSearching.value ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                controller.toggleSearch(); // Toggle search field in the app bar
              },
            ),
          ],
        ),
      
        body: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= SHOP INFO CARD =================
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColor.accent, // Red Violet
                      AppColor.primaryDark, // Oxblood
                    ],
                  ),
                  boxShadow: AppShadow.card,
                ),
                child: Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.shopName.value,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
      
                    SizedBox(height: 5.h),
      
                    Text(
                      "******: ${controller.gstNumber.value}",
                      style: TextStyle(
                        color: Colors.yellow[300],
                        fontSize: 16.sp,
                      ),
                    ),
      
                    SizedBox(height: 5.h),
      
                    Text(
                      "*******: ${controller.mobileNumber.value}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
      
                    SizedBox(height: 5.h),
      
                    Text(
                      "********: ${controller.todayBillsCount.value}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
      
                    Text(
                      "*********: ₹${controller.todayAmount.value}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                )),
              ),
      
              SizedBox(height: 20.h),
      
              Text(
                "Recent Notifications",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
      
              SizedBox(height: 10.h),
      
              // ================= NOTIFICATION LIST =================
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    controller.loadNotifications(); // Reload notifications on pull-to-refresh
                  },
                  child: Obx(() {
                    if (controller.filteredNotifications.isEmpty) {
                      return Center(
                        child: Text(
                          "No notifications found.",
                          style: TextStyle(fontSize: 16.sp),
                        ),
                      );
                    }
      
                    return ListView.builder(
                      itemCount: controller.filteredNotifications.length,
                      itemBuilder: (context, index) {
                        final notif = controller.filteredNotifications[index];
      
                        // Convert the notification time to a valid DateTime format
                        DateTime notifDate = DateFormat('dd/MM/yyyy').parse(notif['time']);
      
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                colors: [Colors.pink.shade300, Colors.pink.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.notifications, color: Colors.white),
                              title: Text(notif['title'], style: TextStyle(color: Colors.white)),
                              subtitle: Text(notif['message'], style: TextStyle(color: Colors.white70)),
                              trailing: Text(
                                timeago.format(notifDate), // Using timeago to format the date
                                style: TextStyle(fontSize: 12.sp, color: Colors.white),
                              ),
                              onTap: () {
                                // Show details in a modal bottom sheet
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return Padding(
                                      padding: EdgeInsets.all(16.w),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            notif['title'],
                                            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 10.h),
                                          Text(notif['message']),
                                          SizedBox(height: 10.h),
                                          Text("Received at: ${notif['time']}"),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

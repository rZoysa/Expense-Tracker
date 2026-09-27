import 'package:expense_tracker/views/shared/widgets/expense_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DashboardLoadingSkeleton extends StatelessWidget {
  const DashboardLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 104.h),
      children: [
        Skeletonizer.zone(
          child: Row(
            children: [
              Bone.iconButton(size: 24.r),
              const Spacer(),
              Bone.text(width: 128.w),
              const Spacer(),
              Bone.iconButton(size: 24.r),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Skeletonizer.zone(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 96.w),
                  SizedBox(height: 10.h),
                  Bone(
                    width: 184.w,
                    height: 34.h,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  SizedBox(height: 8.h),
                  Bone.text(width: 124.w),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Skeletonizer.zone(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(width: 148.w),
                  SizedBox(height: 20.h),
                  Center(child: Bone.circle(size: 156.r)),
                  SizedBox(height: 20.h),
                  ...List.generate(
                    3,
                    (_) => Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Row(
                        children: [
                          Bone.circle(size: 12.r),
                          SizedBox(width: 10.w),
                          Bone.text(width: 88.w),
                          const Spacer(),
                          Bone.text(width: 96.w),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),
        Skeletonizer.zone(
          child: Row(
            children: [
              Bone.text(width: 122.w),
              const Spacer(),
              Bone.text(width: 56.w),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpenseListSkeleton(
            itemCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

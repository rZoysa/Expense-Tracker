import 'package:expense_tracker/views/shared/widgets/expense_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TransactionsLoadingSkeleton extends StatelessWidget {
  const TransactionsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
          child: Skeletonizer.zone(
            child: Column(
              children: [
                Bone(
                  width: double.infinity,
                  height: 56.h,
                  borderRadius: BorderRadius.circular(28.r),
                ),
                SizedBox(height: 16.h),
                Bone(
                  width: double.infinity,
                  height: 48.h,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Bone.iconButton(size: 24.r),
                    const Spacer(),
                    Bone.text(width: 128.w),
                    const Spacer(),
                    Bone.iconButton(size: 24.r),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 40.h,
                  child: Row(
                    children: [
                      Bone(
                        width: 64.w,
                        height: 36.h,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      SizedBox(width: 8.w),
                      Bone(
                        width: 84.w,
                        height: 36.h,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      SizedBox(width: 8.w),
                      Bone(
                        width: 76.w,
                        height: 36.h,
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Bone.text(width: 122.w),
                    const Spacer(),
                    Bone.text(width: 42.w),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        const Expanded(child: ExpenseListSkeleton(itemCount: 7)),
      ],
    );
  }
}

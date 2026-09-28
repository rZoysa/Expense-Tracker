import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ExpenseListSkeleton extends StatelessWidget {
  const ExpenseListSkeleton({
    this.itemCount = 6,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
    super.key,
  });

  final int itemCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer.zone(
      child: ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding ?? EdgeInsets.only(top: 8.h, bottom: 96.h),
        itemCount: itemCount,
        separatorBuilder: (_, _) => Divider(height: 1.h, indent: 72.w),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Bone.circle(size: 44.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.text(width: 132.w),
                      SizedBox(height: 8.h),
                      Bone.text(width: 96.w),
                    ],
                  ),
                ),
                SizedBox(width: 16.w),
                Bone.text(width: 82.w),
              ],
            ),
          );
        },
      ),
    );
  }
}

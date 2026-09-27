import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppLoadingSkeleton extends StatelessWidget {
  const AppLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Tracker')),
      body: SafeArea(
        child: Skeletonizer.zone(
          child: ListView(
            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
            children: [
              Row(
                children: [
                  Bone.iconButton(size: 24.r),
                  const Spacer(),
                  Bone.text(width: 128.w),
                  const Spacer(),
                  Bone.iconButton(size: 24.r),
                ],
              ),
              SizedBox(height: 16.h),
              Bone(
                width: double.infinity,
                height: 124.h,
                borderRadius: BorderRadius.circular(16.r),
              ),
              SizedBox(height: 16.h),
              Bone(
                width: double.infinity,
                height: 260.h,
                borderRadius: BorderRadius.circular(16.r),
              ),
              SizedBox(height: 24.h),
              Bone.text(width: 132.w),
              SizedBox(height: 12.h),
              ...List.generate(
                3,
                (_) => Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: Row(
                    children: [
                      Bone.circle(size: 44.r),
                      SizedBox(width: 12.w),
                      Expanded(child: Bone.text(width: 140.w)),
                      Bone.text(width: 84.w),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

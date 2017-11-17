using System;
using ObjCRuntime;

[assembly: LinkWith ("PayPalRetailSDK", LinkTarget.ArmV7 | LinkTarget.Simulator | LinkTarget.Simulator64 | LinkTarget.Arm64, SmartLink = true, ForceLoad = true, IsCxx = true, LinkerFlags = "-lstdc++")]

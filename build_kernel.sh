#!/bin/bash
#
# Kernel Build Script v4.3
#
# Copyright (C) 2017 Michele Beccalossi <beccalossi.michele@gmail.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#

KERNEL_NAME="primal.hero"

KERNEL_VERSION="3.1.0"
KERNEL_REVISION="0"
KERNEL_BETA="0"
KERNEL_BASE="DQJ1"

DREAM_PATCH="AQI7"
GRACE_PATCH="AQI5"

export ARCH=arm64
export BUILD_JOB_NUMBER=$(grep processor /proc/cpuinfo | wc -l)
export BUILD_CROSS_COMPILE=../gcc-linaro-5.4.1-2017.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-

FUNC_CLEAN_ENVIRONMENT()
{
	tput reset

	echo ""
	echo "=================================================================="
	echo "START : FUNC_CLEAN_ENVIRONMENT"
	echo "=================================================================="
	echo ""

	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			mrproper || exit -1
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			distclean || exit -1

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_CLEAN_ENVIRONMENT"
	echo "=================================================================="
	echo ""

	exit 1
}

FUNC_CUSTOM_CLEAN()
{
	tput reset

	echo ""
	echo "=================================================================="
	echo "START : FUNC_CUSTOM_CLEAN"
	echo "=================================================================="
	echo ""

	echo "◊ Deleting log files..."
	rm -f cfp_log.txt
	rm -f build_kernel.log
	echo ""
	echo "◊ Deleting all the previous builds..."
	rm -rf out/*.zip
	echo ""
	echo "◊ Deleting dtb compilation leftovers..."
	rm -f arch/arm64/boot/dtb.img
	rm -rf arch/arm64/boot/dtb/*
	echo ""
	echo "◊ Cleaning build folder..."
	rm -f build/herolte/dtb
	rm -f build/herolte/zImage
	rm -f build/herolte/.version
	rm -f build/hero2lte/dtb
	rm -f build/hero2lte/zImage
	rm -f build/hero2lte/.version
	echo ""
	echo "◊ Deleting patch related leftovers..."
	rm -rf *.patch
	rm -rf *.diff
	find . -name "*.orig" -delete
	find . -name "*.rej" -delete

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_CUSTOM_CLEAN"
	echo "=================================================================="
	echo ""

	exit 1
}

FUNC_UNKNOWN_INPUT()
{
	tput reset

	echo ""
	echo "=================================================================="
	echo "ERROR : UNKNOWN_INPUT"
	echo "=================================================================="
	echo ""
	echo "Usage: ./build_kernel.sh [option]"
	echo ""
	echo "Currently available options are:"
	echo ""
	echo "1 - to build for herolte"
	echo "2 - to build for hero2lte"
	echo ""
	echo "9 - to run the custom cleaning routine"
	echo "0 - to clean the build environment"
	echo ""
	echo "=================================================================="
	echo "ERROR : UNKNOWN_INPUT"
	echo "=================================================================="
	echo ""

	exit 1
}

if [ $1 == 0 ]; then
	FUNC_CLEAN_ENVIRONMENT
elif [ $1 == 9 ]; then
	FUNC_CUSTOM_CLEAN
elif [ $1 == 1 ]; then
	export MODEL=herolte
elif [ $1 == 2 ]; then
	export MODEL=hero2lte
else
	FUNC_UNKNOWN_INPUT
fi

if [ $KERNEL_BETA == 1 ]; then
	KERNEL_VERSION+=β
fi
if [ $KERNEL_REVISION != 0 ]; then
	KERNEL_VERSION+=-r$KERNEL_REVISION
fi
if ! [ $(whoami) == kylothow ] || ! [ $(hostname) == xda-developers ]; then
	KERNEL_VERSION+=-UNOFFICIAL
fi
export LOCALVERSION=-${KERNEL_NAME}-v${KERNEL_VERSION}

KERNEL_DEFCONFIG=primal-${MODEL}_defconfig

PAGE_SIZE=2048
DTB_PADDING=0

RDIR=$(pwd)
OUTDIR=$RDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$RDIR/scripts/dtc/dtc
INCDIR=$RDIR/include
ZIPDIR=$RDIR/build/$MODEL
EXTDIR=$RDIR/out

FUNC_CLEAN()
{
	echo ""
	echo "=================================================================="
	echo "START : FUNC_CLEAN"
	echo "=================================================================="
	echo ""

	if [ -d $DTSDIR ]; then
		echo -e "◊ Deleting .dtb files in:\n $DTSDIR/"
		rm -rf $DTSDIR/*.dtb
	fi
	if [ -d $DTBDIR ]; then
		echo -e "◊ Deleting all the files in:\n $DTBDIR/"
		rm -rf $DTBDIR/*
	fi
	if [ -a $OUTDIR/dtb.img ]; then
		echo -e "◊ Deleting dtb.img in:\n $OUTDIR/"
		rm $OUTDIR/dtb.img
	fi
	if [ -a $OUTDIR/Image ]; then
		echo -e "◊ Deleting Image in:\n $OUTDIR/"
		rm $OUTDIR/Image
	fi
	if [ -a $ZIPDIR/zImage ]; then
		echo -e "◊ Deleting zImage in:\n $ZIPDIR/"
		rm $ZIPDIR/zImage
	fi
	if [ -a $ZIPDIR/dtb ]; then
		echo -e "◊ Deleting dtb in:\n $ZIPDIR/"
		rm $ZIPDIR/dtb
	fi
	if [ -a $EXTDIR/*-$MODEL.zip ]; then
		echo -e "◊ Deleting zip for $MODEL in:\n $EXTDIR"
		rm $EXTDIR/*-$MODEL.zip
	fi

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_CLEAN"
	echo "=================================================================="
	echo ""
}

FUNC_BUILD_DTIMAGE_TARGET()
{
	echo ""
	echo "=================================================================="
	echo "START : FUNC_BUILD_DTIMAGE_TARGET"
	echo "=================================================================="
	echo ""

	if [ $MODEL == herolte ]; then
		DTSFILES="exynos8890-herolte_eur_open_00 exynos8890-herolte_eur_open_01
				exynos8890-herolte_eur_open_02 exynos8890-herolte_eur_open_03
				exynos8890-herolte_eur_open_04 exynos8890-herolte_eur_open_08
				exynos8890-herolte_eur_open_09"
	elif [ $MODEL == hero2lte ]; then
		DTSFILES="exynos8890-hero2lte_eur_open_00 exynos8890-hero2lte_eur_open_01
				exynos8890-hero2lte_eur_open_03 exynos8890-hero2lte_eur_open_04
				exynos8890-hero2lte_eur_open_08"
	fi

	if ! [ -d $DTBDIR ]; then
		mkdir $DTBDIR
	fi
	cd $DTBDIR
	echo "◊ Processing dts files..."
	echo ""
	for dts in $DTSFILES; do
		echo "=> Processing: ${dts}.dts"
		${CROSS_COMPILE}cpp -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
		echo "=> Generating: ${dts}.dtb"
		$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
	done

	echo ""
	echo "◊ Generating dtb.img..."
	echo ""
	$RDIR/scripts/dtbtool/dtbTool -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_BUILD_DTIMAGE_TARGET"
	echo "=================================================================="
	echo ""
}

FUNC_BUILD_KERNEL()
{
	echo ""
	echo "=================================================================="
	echo "START : FUNC_BUILD_KERNEL"
	echo "=================================================================="
	echo ""
	echo "◊ Build defconfig:	$KERNEL_DEFCONFIG"
	echo "◊ Build model:		$MODEL"

	echo ""
	echo "◊ Generating kernel config..."
	echo ""
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE \
			$KERNEL_DEFCONFIG || exit -1

	echo ""
	echo "◊ Building kernel..."
	echo ""
	make -j$BUILD_JOB_NUMBER ARCH=$ARCH \
			CROSS_COMPILE=$BUILD_CROSS_COMPILE || exit -1

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_BUILD_KERNEL"
	echo "=================================================================="
	echo ""
}

FUNC_BUILD_ZIP()
{
	echo ""
	echo "=================================================================="
	echo "START : FUNC_BUILD_ZIP"
	echo "=================================================================="
	echo ""

	cp $OUTDIR/Image $ZIPDIR/zImage
	cp $OUTDIR/dtb.img $ZIPDIR/dtb

	VERSION=$(grep -Po -m 1 '(?<=VERSION = ).*' $RDIR/Makefile)
	PATCHLEVEL=$(grep -Po -m 1 '(?<=PATCHLEVEL = ).*' $RDIR/Makefile)
	SUBLEVEL=$(grep -Po -m 1 '(?<=SUBLEVEL = ).*' $RDIR/Makefile)
	echo "kernel.version=$KERNEL_VERSION" > $ZIPDIR/.version
	echo "kernel.base=$KERNEL_BASE" >> $ZIPDIR/.version
	echo "dream.patch=$DREAM_PATCH" >> $ZIPDIR/.version
	echo "grace.patch=$GRACE_PATCH" >> $ZIPDIR/.version
	echo "linux.version=$VERSION.$PATCHLEVEL.$SUBLEVEL" >> $ZIPDIR/.version

	if ! [ -d $EXTDIR ]; then
		mkdir $EXTDIR
	fi
	cd $ZIPDIR
	echo "=> Output: $EXTDIR/${KERNEL_NAME}-v${KERNEL_VERSION}${BUILD_TYPE}-${MODEL}.zip"
	echo ""
	zip -r9 $EXTDIR/${KERNEL_NAME}-v${KERNEL_VERSION}${BUILD_TYPE}-${MODEL}.zip * .version -x modules/\*

	echo ""
	echo "=================================================================="
	echo "END   : FUNC_BUILD_ZIP"
	echo "=================================================================="
	echo ""
}

# MAIN FUNCTION
rm -rf ./build_kernel.log
(
	tput reset

	START_TIME=$(date +%s)
	FUNC_CLEAN
	START_COMPILE=$(date +%s)
	FUNC_BUILD_KERNEL
	END_COMPILE=$(date +%s)
	FUNC_BUILD_DTIMAGE_TARGET
	FUNC_BUILD_ZIP
	END_TIME=$(date +%s)

	let "COMPILE_TIME=$END_COMPILE-$START_COMPILE"
	let "ELAPSED_TIME=$END_TIME-$START_TIME"
	echo "◊ Total kernel compile time was $COMPILE_TIME seconds."
	echo "◊ Total build time was $ELAPSED_TIME seconds."
	echo ""
) 2>&1 | tee -a ./build_kernel.log
sed -i '1s/.*//' ./build_kernel.log

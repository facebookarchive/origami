static inline CGFloat POPPixelsToPoints(CGFloat pixels) {
	static CGFloat scale = -1;
	if (scale < 0) {
		scale = [UIScreen mainScreen].scale;
	}
	return pixels / scale;
}
static inline CGFloat POPTransition(CGFloat progress, CGFloat startValue, CGFloat endValue) {
	return startValue + (progress * (endValue - startValue));
}
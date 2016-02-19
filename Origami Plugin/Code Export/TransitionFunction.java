  public float transition (float progress, float startValue, float endValue) {
    return (float) SpringUtil.mapValueFromRangeToRange(progress, 0, 1, startValue, endValue);
  }
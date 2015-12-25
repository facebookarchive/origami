// %@ transition

- (void)toggle%@:(BOOL)on {
  POPSpringAnimation *animation = [self pop_animationForKey:@"%@"];
  
  if (!animation) {
    animation = [POPSpringAnimation animation];
    animation.springBounciness = %@;
    animation.springSpeed = %@;
    animation.property = [POPAnimatableProperty propertyWithName:@"%@Progress" initializer:^(POPMutableAnimatableProperty *prop) {
      prop.readBlock = ^(ViewController *obj, CGFloat values[]) {
        values[0] = obj.%@Progress;
      };
      prop.writeBlock = ^(ViewController *obj, const CGFloat values[]) {
        obj.%@Progress = values[0];
      };
      prop.threshold = 0.001;
    }];
    
    [self pop_addAnimation:animation forKey:@"%@"];
  }
  
  animation.toValue = on ? @(1.0) : @(0.0);
}
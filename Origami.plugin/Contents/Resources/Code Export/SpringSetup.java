    %@Spring = springSystem.createSpring()
        .setSpringConfig(SpringConfig.withBouncinessAndSpeed(%@, %@))
        .addListener(new SimpleSpringListener() {
          @Override
          public void onSpringUpdate(Spring spring) {
            set%@Progress((float) spring.getCurrentValue());
          }
        });
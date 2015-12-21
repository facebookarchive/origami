---
title: States
layout: documentation
css: /public/css/documentation.css
weight: 3
---

Every prototype has multiple states it can transition between. In Origami, Switch patches help keep track of which state you are in. They are like light switches and can be toggled with [interaction patches](../Interactions).

## State patches

  <ul class="bulleted-list">
    <li>
      [Switch &rarr;](../../patches/Switch)
      <br>
      The Switch patch is like a light switch: turning it on keeps it on, and turning it off keeps it off. They are helpful to build simple two-state interactions, e.g. showing and hiding comments in a popover.
      <ul class="patch-chain">
        <li>
          <div class="patch-block">
            <div class="patch producer">
              <h3>Interaction 2</h3>
              <ul class="inputs">
                <li>Enable</li>
              </ul>
              <ul class="outputs">
                <li>Down</li>
                <li>Up</li>
                <li>Tap</li>
                <li>Drag</li>
                <div class="cable"></div>
              </ul>
              <hr>
            </div>
          </div>
        </li>
        <li>
          <div class="patch-block">
            <div class="patch processor">
              <h3>Switch</h3>
              <ul class="inputs">
                <li>Turn On <span class="patch-value">&#10003;</span></li>
                <li>Turn Off</li>
              </ul>
              <ul class="outputs">
                <li>On / Off</li>
                <div class="cable"></div>
              </ul>
              <hr>
            </div>
          </div>
        </li>
        <li>
          <div class="patch-block">
            <div class="patch consumer">
              <h3>Layer</h3>
              <ul class="inputs">
                <li>Enable <span class="patch-value">&#10003;</span></li>
              </ul>
              <hr>
            </div>
          </div>
        </li>
      </ul>
      Multiple Switch patches can combined with [Logic patches](../../patches/Logic) to build on top of each other, e.g. opening a composer with different attachment options which the user can toggle.
      <br><br>
    </li>
    <li>
      [Index Switch &rarr;](../../patches/Index-Switch)
      <br>
      Index Switch patches are useful for mutually exclusive states that cannot coexist, e.g. a tab bar.
      <br><br>
      Index Switches are commonly used with [Multiplexers](../../patches/Multiplexer) to pass different values depending the state. For example, if you wanted to change a navigation bar title between 3 states:
      <ul class="patch-chain">
        <li>
          <div class="patch-block">
            <div class="patch processor">
              <h3>Index Switch</h3>
              <ul class="inputs">
                <li>Input 0 <span class="patch-value">&#10003;</span></li>
                <li>Input 1</li>
                <li>Input 2</li>
              </ul>
              <ul class="outputs">
                <li>Index</li>
                <div class="cable"></div>
              </ul>
              <hr>
            </div>
          </div>
        </li>
        <li>
          <div class="patch-block">
            <div class="patch processor">
              <h3>Multiplexer</h3>
              <ul class="inputs">
                <li>Source Index <span class="patch-value">0</span></li>
                <li>Source #0 <span class="patch-value">News Feed</span></li>
                <li>Source #1 <span class="patch-value">Notifications</span></li>
                <li>Source #2 <span class="patch-value">Profile</span></li>
              </ul>
              <ul class="outputs">
                <li>Output</li>
                <div class="cable"></div>
              </ul>
              <hr>
            </div>
          </div>
        </li>
        <li>
          <div class="patch-block">
            <div class="patch consumer">
              <h3>Text Layer</h3>
              <ul class="inputs">
                <li>Text <span class="patch-value">News Feed</span></li>
              </ul>
              <hr>
            </div>
          </div>
        </li>
      </ul>
    </li>
    <li>
      [Counter 2 &rarr;](../../patches/Counter-2)
      <br>
      Counter patches are useful for mutually exclusive states that cannot coexist, and increment in a fixed order e.g. an onboarding flow.
      <ul class="patch-chain">
        <li>
          <div class="patch-block">
            <div class="patch producer">
              <h3>Counter 2</h3>
              <ul class="inputs">
                <li>Increase</li>
                <li>Decrease</li>
                <li>Maximum Count <span class="patch-value">2</span></li>
              </ul>
              <ul class="outputs">
                <li>Number</li>
                <div class="cable"></div>
              </ul>
              <hr>
            </div>
          </div>
        </li>
        <li>
          <div class="patch-block">
            <div class="patch processor">
              <h3>Multiplexer</h3>
              <ul class="inputs">
                <li>Source Index <span class="patch-value">2</span></li>
                <li>Source #0 <span class="patch-value">Enter information</span></li>
                <li>Source #1 <span class="patch-value">Verify email</span></li>
                <li>Source #2 <span class="patch-value">Finished!</span></li>
              </ul>
              <ul class="outputs">
                <li>Output</li>
                <div class="cable"></div>
              </ul>
              <hr>
            </div>
          </div>
        </li>
        <li>
          <div class="patch-block">
            <div class="patch consumer">
              <h3>Text Layer</h3>
              <ul class="inputs">
                <li>Text <span class="patch-value">Finished!</span></li>
              </ul>
              <hr>
            </div>
          </div>
        </li>
      </ul>
    </li>
  </ul>


## Index numbers represent states
Both Switch and Index Switch patches output a number for the state that is active. Switch patches output a 0 (off) or a 1 (on), and Index Switch patches output a number starting from 0 for the first state, to 1 for the 2nd, and so on:

<ul class="bulleted-list">
  <li>Index 0 &rarr; Initial state / Off State</li>
  <li>Index 1 &rarr; 2nd state / On State</li>
  <li>Index 2 &rarr; 3rd state</li>
  <li>Index 3 &rarr; 4th state</li>
  <li>...</li>
</ul>

<br>

Next: [Animations &rarr;](../Animations)
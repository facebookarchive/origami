---
title: Iterators
layout: documentation
css: /public/css/documentation.css
---

[Iterators](../../patches/Iterator) are an easy way to minimize repetitive patches that do the same thing. They are similar to loops in programming. A common reason to use Iterators is to display many of the same Layers, with different attributes (e.g. a News Feed). This way if you update one Layer you update all of them at the same time &mdash; it will make your prototyping much faster.

## Using Current Index to build repeating layouts
The foundation of working with Iterators is to using the Current Index value from [Iterator Info](../../patches/Iterator-Info). Lets say you have an Iterator with a count of 5. Iterator basically clones all the contents 5 times, and for each clone it provides a different index from Iterator Info (where the first clone has an index of 0, second clone has an index of 1, and so on).

In practice, one of the most common modifications to Current Index is multiplying it by an offset to place stack items horizontally or vertically. For example, if you were prototyping the Instagram feed, where each feed item is about the same height (let's say 850 for a 750px wide screen, with 100px for padding and author and caption), we would connect a Math patch to Current Index, set to multiply by 750px, and plug that into the Y Position of the Layer patch rendering the feed item.

## Using Current Index to have dynamic content
Current Index is also very useful to handle displaying dynamic content from a structure.

Let's say we have a list of friends. For each friend you want to have a different name. In an Iterator, you cannot manually input the text for each Text Layer. However, if you create a structure of names outside the Iterator (With [Structure Creator](../../patches/Structure-Creator) set to String), you can pass in that structure of names and use [Structure Index Member](../../patches/Structure-Index-Member) with Current Index to get each name for each index.

## Challenges and Caveats
There are several caveats with Iterators that can be limiting, and one crash-inducing issue. However, iterators are helpful enough to justify their use even with these issues.

  **Changing the Iteration count may cause a crash**
  <br>
  If an Iterator has a Layer patch within, and you change the Iterator count while the composition is running, it will most likely crash. This is due to a bug with a patch called Feedback inside Layers, which helps snap layers to pixels and is difficult to fix at the moment.

  Solution: Stop the composition before changing the Iterator count. If you wish to have a dynamic Iterator count (e.g. an interaction will cause new items to be displayed in a News Feed), set the count to the highest it can be, and use Conditionals inside the Iterator to hide the inactive Layers based on the index.

  **Only the last iteration values are visible in the editor**
  <br>
  Following the patch values in your composition is useful to help debug a problem. However, Iterators only show the values for the last iteration (e.g. if you have 10 iterations, it only shows the values for the 10th one). There isn't a real workaround for this, except changing the Iteration count or setting a Max on the index.

  **Interaction patches do not work properly**
  <br>
  Due to the way we built Interaction 2, hit testing is highly complicated and not supported inside Iterators. If you want to have interactions in an Iterator, you can manually implement hit testing in a separate Iterator that checks the X/Y positions of the Touch patch, and compares them with the rendered Layer positions.

  **Passing values out of Iterators is difficult**
  <br>
  There are two different methods depending on if your Iterator has a blue consumer patch or not:

  <ul class="bulleted-list">
  	<li>
      No consumer patch inside
      <br>
      Lets say you want to pass a number out of an Iterator. If you publish it, how does the Iterator know which value to pass out? The answer is to pass all of the values out as a structure and pick the one you want from within.
      <br><br>
      To create a structure of the values within the Iterator, we can use the Queue patch, which works very well with Iterators if the Queue size is the same as the Iterator count. Simply enable Filling, and pass in the value you want to store. Then publish the Queue's output structure. Now you can access the value you want outside of the Iterator with a [Structure Index Member](../../patches/Structure-Index-Member).
    </li>
    <li>
      Consumer patches inside
      <br>
      Due to the QC limitation that blue consumer patches cannot have any outputs, you have to use a [Wireless Broadcaster](../../patches/Wireless-Broadcaster) to pass any values out. The Wireless Broadcaster doesn't work 100% properly in an Iterator (only passes the last index) and will require a workaround before it can pass out a value from a specific index that is not the last one.
      <br><br>
      The basic concept of the workaround is to only enable the Wireless Broadcaster for the index that you want to pass a value out of. Wireless Broadcasters have a hidden Enable port that you can use by right-clicking and inserting an input splitter for Enable.
      <br><br>
      You can also combine Wireless Broadcaster with the Queue implementation above.
    </li>
  </ul>
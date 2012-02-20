## Deployment

The production machines always run off the `stable` branch. When we deploy,
the deploy scripts should:

* Merge `stable` into `master`. This ensures that the two code paths come
together relatively frequently. This also guarantees that we'll pick up any
stray hotfixes that didn't get merged back.

* Create a tag on `stable`. Use the deploy number? Date? Both?

* Update everything on the production machines.

* Some kind of Apache/haproxy flag that allows us to change the doc root for
the office IP? Essentially the world would see the old code while we see the
new code. How would this work with migrations?
  + [Flickr], [Disqus] and [Etsy] use *feature flippers*, which allow them to
    deploy code "in the dark" and turn it off and on at will with a control
    panel.  I (James) am not sold on this idea, but it's an interesting one.

[Flickr]: http://code.flickr.com/blog/2009/12/02/flipping-out/
[Disqus]: http://blog.disqus.com/post/789540337/partial-deployment-with-feature-switches
[Etsy]: http://codeascraft.etsy.com/2011/02/04/how-does-etsy-manage-development-and-operations/


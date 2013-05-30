describe "rest", ->

  adapter = null

  beforeEach ->
    require('./_shared').setupRest.apply(this)
    adapter = @adapter

  context "one->one", ->

    beforeEach ->
      class @Post extends Ep.Model
        title: Ep.attr('string')
      @App.Post = @Post

      class @User extends Ep.Model
        name: Ep.attr('string')
        post: Ep.belongsTo(@Post)
      @App.User = @User

      @Post.reopen
        user: Ep.belongsTo(@User)

      @container.register 'model:post', @Post, instantiate: false
      @container.register 'model:user', @User, instantiate: false


    it 'child can be null', ->
      @adapter.r['GET:/posts/1'] = posts: {id: 1, title: 'mvcc ftw', user_id: null}

      session = @adapter.newSession()

      ajaxCalls = @adapter.h
      session.load(@Post, 1).then (post) ->
        expect(post.id).to.eq("1")
        expect(post.title).to.eq("mvcc ftw")
        expect(post.user).to.be.null


    it 'loads lazily', ->
      @adapter.r['GET:/posts/1'] = posts: {id: 1, title: 'mvcc ftw', user_id: 2}
      @adapter.r['GET:/users/2'] = users: {id: 2, name: 'brogrammer', post_id: 1}
      
      session = @adapter.newSession()

      ajaxCalls = @adapter.h
      session.load(@Post, 1).then (post) ->
        expect(ajaxCalls).to.eql(['GET:/posts/1'])
        expect(post.id).to.eq("1")
        expect(post.title).to.eq('mvcc ftw')
        user = post.user
        expect(user.id).to.eq("2")
        expect(user.name).to.be.undefined

        post.user.then ->
          expect(ajaxCalls).to.eql(['GET:/posts/1', 'GET:/users/2'])
          expect(user.name).to.eq('brogrammer')
          expect(user.post.equals(post)).to.be.true
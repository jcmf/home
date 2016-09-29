exports.newGame = (args...) -> new Game args...

error = (msg) -> throw new Error msg or 'assertion failed'
assert = (ok, msg) -> if not ok then error msg

meta = require './meta'

nameFns = (k, v) ->
  switch typeof v
    when 'function' then try v.displayName = k
    when 'object'
      for subk, subv of v
        nameFns "#{k}.#{subk}", subv
  return

{encode} = require './json'
{sha256, BASE32} = require './sha256'

left = {}
right = {}
back = {}
dirDest = {}
do ->
  dirs = ['NORTH', 'EAST', 'SOUTH', 'WEST']
  for k, i in dirs
    right[k] = dirs[(i+1) % 4]
    back[k] = dirs[(i+2) % 4]
    left[k] = dirs[(i+3) % 4]
    dirDest[k] = k
    dirDest[k[0]] = k

rotDest = {}
do ->
  rotDest[k] = left for k in 'LEFT L COUNTERCLOCKWISE CCW'.split /\s+/g
  rotDest[k] = right for k in 'RIGHT R CLOCKWISE CW'.split /\s+/g

link = (what) -> "{{|CONTEMPLATE }#{what}}"
theLink = (what) ->
  if theName = things[what]?.theName then link theName # just SWEETIE?
  else "the #{link what}"

locs =
  FUTON:
    syns: 'COUCH BED'
    standingIn: 'sitting on'
    NORTH: to: 'LIVING ROOM'
    shooable: true
    bcom: (what) -> """
      YES THANK YOU FOR WARNING US.
      WE DO NOT WISH TO INTERFERE WITH YOUR ACTIVITIES.
      """
    scom: (what) -> """
      Maybe we can have some cuddles on the #{link what} when I get home!
      """
    scomBugs: (what) ->
      if @toldBugs(what)
        """
        There must be some way to convince them to get off of our
        #{link what}!
        """
      else
        """
        That does not sound conducive to cuddles on the #{link what}!
        There must be some way to get them off!
        """
  'LIVING ROOM':
    shooable: -> @isGood 'WINDOW'
    bcom: (what) -> """
      YES THE #{link 'WINDOW'} IS A MORE EFFICIENT ROUTE.
      THANK YOU SO MUCH FOR OPENING IT FOR US!
      """
    bcomBugs: ->
      if @sawGood('DOOR')
        "YES WE REQUIRE ACCESS TO THE #{link 'FRONT DOOR'}."
      else
        "YES WE HAVE A QUESTION ABOUT THE #{link 'FRONT DOOR'}."
    scom: -> "Ten cubic meters is the perfect size!"
    scomBugs: -> "We have to live somewhere.  What will we do?"
    EAST: to: 'KITCHEN'
    WEST:
      name: 'FRONT DOOR'
      syns: 'DOOR'
      bump: (msg, what) ->
        if @isOpen what then @noNav things[what].open.name
        else "You could {OPERATE #{the what}}."
      shooable: -> @isGood 'WINDOW'
      bcom: (what) -> """
        YES THE #{link 'WINDOW'} IS A SUPERIOR ALTERNATIVE.
        THANK YOU SO MUCH!
        """
      bcomBugs: (what) ->
        if not @sawGood what
          """
          YES PLEASE DEMONSTRATE THE OPERATION OF THE #{link what}
          SO THAT WE MAY EVALUATE ITS RELEVANCE TO OUR STRATEGIC INTERESTS.
          THANK YOU SO MUCH!
          """
        else if not @isGood what
          """
          YES
          #{if @sawYouBad what then "YOU SEEM TO HAVE CLOSED THAT BY MISTAKE" else "IT IS IN THE WAY."}
          COULD YOU {DO SOMETHING ABOUT THAT|OPERATE FRONT DOOR}?
          UNFORTUNATELY WE ARE UNABLE TO PASS THROUGH THE #{link 'WINDOW'},
          LEAVING THE #{link what} AS OUR ONLY POSSIBLE MEANS OF ACCESS TO
          THE #{link 'TREE'}.  WE HAVE AN ENTIRE CIVILIZATION TO FEED.
          THANK YOU FOR YOUR UNDERSTANDING!
          """
        else if not @isGood 'REFRIGERATOR'
          """
          YES WE UNDERSTAND, HOWEVER BEFORE WE CAN PROPERLY DISCUSS THIS
          MATTER WE MUST REGRETFULLY BRING UP YOUR INCONSISTENT BEHAVIOR
          WITH RESPECT TO THE #{link 'REFRIGERATOR'}.  IF WE CANNOT
          REACH THEM WITH THE DELICIOUS NUTRIENTS FROM THE #{link 'TREE'},
          OUR PEOPLE IN THE #{link 'HIVE'} WILL SLOWLY STARVE TO DEATH.
          THANK YOU SO MUCH!
          """
        else
          """
          YES WE UNDERSTAND.  UNFORTUNATELY
          #{if @sawBad 'WINDOW' then "THE #{link 'WINDOW'} HAS CLOSED AGAIN" else "WE ARE UNABLE TO PASS THROUGH THE #{link 'WINDOW'}"}
          LEAVING THE #{link what} AS OUR ONLY MEANS OF ACCESS TO THE
          #{link 'TREE'}.  WE HAVE AN ENTIRE CIVILIZATION TO FEED.
          THANK YOU FOR YOUR UNDERSTANDING!
          """
      scom: (what) ->
        if @getHits what
          "Maybe the locksmith can take care of the hole as well."
        else
          """
          Do not worry, sweetie, the locksmith will be here tomorrow.
          I am certain you can protect our home in the meantime!
          """
      scomBugs: (what) ->
        """
        How will we get in and out of our apartment if there are
        #{link 'BUGS'} all over the #{link what}?
        """
      desc: (msg, what) ->
        return msg if not @isOpen what
        """
        #{msg}
        Through the #{link what} you can see the #{link 'LAWN'}.
        """
      postHit: (hits, msg, what) ->
        return msg if not @bugs or hits != 1 or @isOpen(what)
        return msg + " " + if @bugsAreOut()
          """
          #{link 'BUGS'} begin to fly in and out of the hole.
          """
        else
          """\n\n
          Some of the #{link 'BUGS'} fly through the hole in the #{link what}!
          Soon there are #{link 'BUGS'} flying in and out of the hole.
          """
      use: (msg, what) ->
        if not @isOpen what
          msg += " Through the #{link what} you can see the #{link 'LAWN'}."
          if @bugs and not @getHits(what)
            if @bugsAreOut() then msg += """\n\n
              #{link 'BUGS'} begin to fly back and forth through the
              #{link what}.
              """
            else msg += """\n\n
              Some of the #{link 'BUGS'} fly out the #{link what}!
              Soon there are #{link 'BUGS'} flying back and forth
              through the open #{link what}.
              """
        else if @bugsAreOn(what) and not @getHits(what) then msg += """\n\n
          "EXCUSE US PLEASE BUT SOMETHING AWFUL HAS OCCURRED.
          WE CAN NO LONGER GET THROUGH THE DOOR!"
          """
        return msg
      open:
        name: 'LAWN'
        syns: ['FRONT LAWN', 'YARD', 'FRONT YARD', 'GRASS']
        prep: 'beyond'
        noNav: true
        shooable: false
        bugsAreOn: -> @bugsAreOut()
        bcom: (what) ->
          """
          YES THAT SOUNDS OKAY BUT GRASS IS NOT REALLY OUR THING.
          WE ARE MORE INTERESTED IN THE #{link 'TREE'}.
          """
        bcomBugs: (what) ->
          """
          YES THE #{link what} IS OKAY BUT WE PREFER THE #{link 'TREE'}.
          IT IS RIGHT AROUND THE CORNER.
          """
        scom: (what) ->
          """
          Maybe if we ignore it, it will revert to a lower energy state.
          """
        scomBugs: (what) ->
          """
          Plenty of space for them out there.
          """
    NORTH:
      name: 'WORKBENCH'
      syns: 'BENCH'
      use: -> @toggleLaser()
      desc: (msg) ->
        msg = """
          #{msg}

          On the #{link 'WORKBENCH'}
          #{if @laser then 'is' else 'are'}
          a #{link 'SOLDERING TOOL'}
          """
        msg += " and a #{link 'LASER'}" if not @laser
        msg += '.'
      shooable: true
      bcom: (what) ->
        """
        YES WE ARE DELIGHTED TO PARTICIPATE IN YOUR BUSINESS
        PLAN BY KEEPING OFF THE #{link what}.
        """
      scom: (what) ->
        """
        No, I think that is the most logical place.
        You need space for your business, sweetie.
        """
      scomBugs: (what) -> "Will you be able to work like that?"
      items:
        'SOLDERING TOOL':
          syns: 'TOOL'
          use: -> @toggleLaser()
          shooable: true
          bcom: (what) ->
            """
            YES THANK YOU SO MUCH FOR WARNING US ABOUT THIS DANGEROUS
            IMPLEMENT.
            """
          scom: (what) -> "Maybe you can show me when I get home."
          scomBugs: (what) ->
            """
            Can you still use the #{link what} if it has
            #{link 'BUGS'} on it?
            """
        LASER:
          bcom: (what) ->
            if @getHits 'HIVE'
              """
              YES PLEASE BE CAREFUL WITH THAT.
              WE HAVE REASON TO BELIEVE THAT IT MAY BE DANGEROUS.
              """
            else if not @saw_laser
              """
              YES OF COURSE, FOR BUSINESS PURPOSES.
              WE UNDERSTAND THIS CONCEPT.
              WOULD YOU DEMONSTRATE?
              """
            else
              """
              YES IT IS VERY IMPRESSIVE PROBABLY.
              """
          scom: (what) ->
            if not @used_laser
              """
              I think laser-cut jigsaw puzzles are bound to be a best seller!
              """
            else if not @getHits 'HIVE'
              """
              Oh dear.  I thought you were just going to make jigsaw puzzles?
              """
            else
              """
              Sweetie, calm down.  It will be all right.
              """
          #use: -> XXX
  KITCHEN:
    shooable: false
    bcomBugs: (what) ->
      """
      YES IT IS SO MUCH MORE SPACIOUS THAN THE INSIDE OF THE
      #{link 'REFRIGERATOR'}!
      THANK YOU AGAIN FOR REVEALING THIS TO US!
      """
    scom: (what) ->
      """
      I knew we would find an apartment with no running water if we
      looked hard enough!  So perfect.
      """
    scomBugs: (what) ->
      """
      If the #{link what} is overrun, we might need to find somewhere else
      to store batteries and things.
      """
    NORTH:
      name: 'WINDOW'
      hit: (hits, msg, what) ->
        msg += if hits is 1
          " The beam shatters the #{link what}!" + if not @bugs then ''
          else if @bugsAreOut()
            """\n\n
            Some of the #{link 'BUGS'} fly out the #{link what}!
            Soon there are #{link 'BUGS'} flying back and forth
            between the #{link 'REFRIGERATOR'} and the #{link 'TREE'}.
            """
          else
            """\n\n
            #{link 'BUGS'} begin to fly back and forth through the
            #{link what} between the #{link 'REFRIGERATOR'} and the
            #{link 'TREE'}.
            """
        else
          " The beam passes harmlessly through the broken #{link what}."
        @maybeWin hits, msg, what
      leave: (msg, what) ->
        return msg if not @isOpen what
        @close what
        msg += "\n\nThe #{link what} slides closed as you {ROTATE} away."
        return msg if not @bugs or @isGood(what)
        """
        #{msg}

        "NO WAIT PLEASE THE #{link what} IS CLOSED NOW!  HELP!"

        --more--
        """
      use: (msg, what) ->
        if not @isOpen(what) then msg = """
          You {OPERATE #{the what}}.

          The #{link what} does not want to stay open on its own!
          You hold it open for now.
          """
        return msg if not @bugs or @getHits(what)
        "#{msg}\n\n" + if @isOpen(what) # closing
          """
          "EXCUSE US PLEASE BUT THERE HAS BEEN A TERRIBLE TRAGEDY.
          WE ARE NO LONGER ABLE TO PASS THROUGH THE #{link what}."
          """
        else if @bugsAreOut()
          """\n\n
          #{link 'BUGS'} begin to fly back and forth through the
          #{link what} between the #{link 'REFRIGERATOR'} and the
          #{link 'TREE'}.
          """
        else
          """\n\n
          Some of the #{link 'BUGS'} fly out the #{link what}!
          Soon there are #{link 'BUGS'} flying back and forth
          between the #{link 'REFRIGERATOR'} and the #{link 'TREE'}.
          """
      shooable: false
      bcomBugs: (what) ->
        if not @sawGood what
          """
          YES IN ANCIENT TIMES IT WAS MUCH EASIER TO FLY THROUGH
          THIS #{link what}.  HOWEVER WE SEEM TO BE HAVING SOME
          DIFFICULTY.  THANK YOU FOR ASKING.
          """
        else if @isGood what
          if @isGood 'REFRIGERATOR'
            """
            YES WE CAN USE THIS ROUTE TO BRING SUSTENANCE FROM
            THE #{link 'TREE'} TO THE #{link 'HIVE'}.
            THANK YOU SO MUCH FOR YOUR ASSISTANCE!
            """
          else
            """
            YES THIS IS OUR
            #{if @isGood 'FRONT DOOR' then 'BEST' else 'ONLY'}
            ROUTE TO THE DELECTABLE #{link 'TREE'}, HOWEVER WE
            ARE UNABLE TO GET TO THE #{link 'HIVE'} FROM HERE.
            ALL IS LOST!  THANK YOU FOR LISTENING.
            """
        else if @isGood 'FRONT DOOR'
          """
          YES THE #{link 'FRONT DOOR'} IS WELL AND GOOD BUT THIS
          INVITING OPENING STILL DRAWS US TO THE #{link 'TREE'}.
          THANK YOU SO MUCH FOR YOUR INTEREST!
          """
      scom: (what) ->
        if @getHits what
          """
          That sounds like an improvement, actually.
          I never did figure out how to get it to stay open.
          """
        else if not @wasGood what
          """
          It was painted shut, but I was able to pry it open.
          """
        else
          """
          Did I mention?  It keeps sliding closed on its own.
          """
      scomBugs: (what) ->
        """
        Yes, presumably it is better to let them out the #{link what}.
        More #{link 'BUGS'} outside means fewer in the #{link 'KITCHEN'}.
        That is logical!
        """
      desc: (msg, what) ->
        """
        #{msg}
        Through the #{link what} you see a #{link 'TREE'}.
        """
      open:
        name: 'TREE'
        syns: ['CRAB APPLES', 'CRABAPPLES', 'APPLES', 'APPLE', 'CRAB']
        prep: 'outside'
        shooable: false
        bugsAreOn: -> @bugsAreOut()
        scom: (what) ->
          "They are crab apples.  The humans do not like to eat them."
        scomBugs: (what) ->
          "I guess the #{link 'BUGS'} must like crab apples."
        bcom: (what) ->
          """
          YES WE REMEMBER THIS FROM ANCIENT TIMES.
          WE MUST ESTABLISH A SUPPLY ROUTE, OR OUR PEOPLE WILL STARVE.
          """
        bcomBugs: (what) ->
          if not @isGood('FRONT DOOR') and not @isGood('WINDOW')
            """
            YES WE MUST RE-ESTABLISH A SUPPLY ROUTE TO THE #{link what}
            OR WE ARE DOOMED TO STARVATION.  THANK YOU FOR ASKING!
            """
          else if @isGood('REFRIGERATOR')
            """
            YES WE HAVE ESTABLISHED A SUPPLY ROUTE BETWEEN THE #{link what}
            AND THE #{link 'HIVE'}.  THANK YOU SO MUCH!
            """
          else
            """
            YES WE HAVE ESTABLISHED A SUPPLY ROUTE TO THE #{link what}.
            HOWEVER WE ARE UNABLE TO RETURN ITS DELICIOUS NUTRIENTS
            TO THE #{link 'HIVE'}.  OUR CIVILIZATION IS DOOMED.
            THANK YOU SO MUCH FOR YOUR ASSISTANCE.
            """
    EAST:
      name: 'CUPBOARD'
      syns: 'COUNTER PANTRY'
      desc: (msg, what) ->
        return msg if @bugs or not @isOpen(what)
        """
        #{msg}
        There is nothing in the #{link what}.
        """
      open: null
      use: (msg, what) ->
        if @isOpen what # closing
          return msg if not @bugsAreOn(what)
          return """
            As you {OPERATE THE #{what}},
            #{link 'BUGS'} swarm out and settle on its outside surface.

            The #{link what} is now closed.
            """
        return "#{msg}\n\n" + if not @bugsAreOn(what)
          "There is nothing in the #{link what}!"
        else if @shooed(what)
          """
          There is nothing in the #{link what}.

          The #{link 'BUGS'} fly away from the #{link what}!
          """
        else
          "The #{link what} is full of #{link 'BUGS'}!"
      postHit: (hits, msg, what) ->
        if not @isOpen(what) and hits is 1 and @shooed(what)
          newMsg = "The #{link 'BUGS'} fly away from the #{link what}!"
          if msg instanceof Array then msg.push newMsg
          else msg = "#{msg}\n\n#{newMsg}"
        return msg
      shooable: (what) -> @wasGood(what)
      bcom: (what) ->
        """
        YES YOU ARE RIGHT IT IS BORING IN THERE.
        THANK YOU SO MUCH FOR POINTING THAT OUT.
        """
      bcomBugs: (what) ->
        """
        YES THIS IS POTENTIALLY INTERESTING.
        PLEASE {OPEN IT NOW|OPERATE THE #{what}}
        SO THAT WE CAN EVALUATE ITS CONTENTS.
        THANK YOU SO MUCH.
        """
      scom: (what) ->
        """
        Sorry, I think I ate the last of the triple-As on my way out
        this morning.  Unless you put some in the #{link 'REFRIGERATOR'}?
        """
      scomBugs: (what) ->
        """
        If the #{link what} is overrun, we might need to find somewhere else
        to store batteries and things.  By the #{link 'FUTON'}, maybe?
        Did you say they were in there too?
        """
    SOUTH:
      name: 'REFRIGERATOR'
      syns: 'FRIDGE REFRIDGERATOR ICEBOX FREEZER'
      postHit: (hits, msg, what) ->
        return @enterBugs msg if not @bugs
        if hits is 1 and not @isOpen(what)
          msg += " #{link 'BUGS'} begin to fly in and out of the hole!"
        @maybeWin hits, msg, what
      leave: (msg, what) ->
        return msg if not @isOpen what
        @close what
        msg = "#{msg}\n\nThe #{link what} swings shut as you {ROTATE} away."
        msg += if @getHits what
          """ The #{link 'BUGS'} continue to fly back and forth through the
            hole in the #{link what}."""
        else
          """\n\n
          "NO WAIT COME BACK THE #{link what} HAS CLOSED AGAIN WE ARE DOOMED!"
          --more--
          """
      desc: (msg, what) ->
        return msg if not @isOpen what
        """
        #{msg}
        All space inside the #{link what} is filled by
        some kind of #{link 'HIVE'}.
        """
      use: (msg, what) ->
        if not @bugs
          msgs = @enterBugs msg
          msgs.push """
            The #{link what} does not want to stay open on its own!
            You hold it open for now.
            """
          msgs
        else if not @isOpen(what)
          msg = """
            You {OPERATE #{the what}}.

            The #{link what} does not want to stay open on its own!
            You hold it open for now.

            All space inside the #{link what} is filled by
            some kind of #{link 'HIVE'}.
            """
          if not @getHits(what) then msg += """\n\n
            #{link 'BUGS'} begin to fly in and out of the #{link what}!
            """
          msg
        else if not @getHits(what)
          """
          #{msg}

          "EXCUSE US BUT SOMETHING HORRIBLE HAS JUST HAPPENED!
          WE ARE NO LONGER ABLE TO GET BACK INTO THE #{link what}!"
          """
      shooable: false
      scom: (what) ->
        "I have never actually opened it.  Does it even work?"
      scomBugs: (what) ->
        "So they have been in there since we moved in?  Longer, I guess."
      bcomBugs: (what) ->
        """
        YES THE #{link what} IS WHERE OUR CIVILIZATION EVOLVED.
        IT WILL ALWAYS BE OUR NATIVE LAND!

        """ + if not @isGood what
          """
          UNFORTUNATELY WE ARE CUT OFF FROM OUR #{link 'HIVE'}.
          IT IS QUITE TRAGIC.  THANK YOU SO MUCH FOR YOUR CONCERN.
          """
        else if @isGood('WINDOW') or @isGood('FRONT DOOR')
          """
          THANK YOU SO MUCH FOR YOUR ASSISTANCE IN AVERTING DISASTER!
          """
        else
          """
          UNFORTUNATELY WE HAVE NOT BEEN ABLE TO
          #{if @bugsAreOut() then 'RE-' else ''}ESTABLISH
          A FOOD SUPPLY ROUTE.  OUR CIVILIZATION IS DOOMED.
          THANK YOU SO MUCH FOR ASKING!
          """
      open:
        name: 'HIVE'
        syns: [
          'NEST'
          'COLONY'
          'CIVILIZATION'
          'QUEEN' # XXX drop "QUEEN" compat syn?
          'MATRIX'
          'COMPLEX MATRIX'
          'COMPLEX'
          'SUBSTANCE'
          'SEMI-TRANSPARENT SUBSTANCE'
          'SEMI TRANSPARENT SUBSTANCE'
          'SEMITRANSPARENT SUBSTANCE'
          'ORGANIC SUBSTANCE'
          'SEMI-TRANSPARENT ORGANIC SUBSTANCE'
          'SEMI TRANSPARENT ORGANIC SUBSTANCE'
          'SEMITRANSPARENT ORGANIC SUBSTANCE'
          'ORGANIC'
          'SEMI-TRANSPARENT'
          'SEMI TRANSPARENT'
          'SEMITRANSPARENT'
        ]
        secret: true
        prep: 'in'
        shooable: false
        bcomBugs: (what) ->
          """
          YES THE #{link what} HAS BEEN OUR HOME FOR GENERATIONS.

          """ + if not @isGood('REFRIGERATOR')
            """
            WE MUST RE-ESTABLISH A RELIABLE ROUTE IN AND OUT OF
            THE #{link 'REFRIGERATOR'} OR WE WILL DIE ALONE OUT HERE.
            THANK YOU FOR ASKING!
            """
          else if @isGood('WINDOW') or @isGood('FRONT DOOR')
            """
            THANKS TO YOUR TIRELESS EFFORTS ON OUR BEHALF WE HAVE
            SECURED A SUPPLY ROUTE TO DELIVER DELICIOUS NUTRIENTS TO
            OUR PEOPLE FOREVER.
            """
          else
            """
            UNFORTUNATELY THE #{link 'REFRIGERATOR'}'S NATURAL RESOURCES
            HAVE BEEN DEPLETED.
            WE MUST ESTABLISH A CONTINUOUS SUPPLY OF DELICIOUS NUTRIENTS
            OR OUR CIVILIZATION IS DOOMED.
            THANK YOU SO MUCH FOR YOUR ASSISTANCE!
            """
        scomBugs: ->
          """
          I guess there is no question of keeping anything in the
          #{link 'REFRIGERATOR'} anymore.
          """
        descHit: -> null
        hit: (hits, msg, what) ->
          switch hits
            when 1
              [
                "#{msg} The beam strikes the {H|CONTEMPLATE HIVE}...
                wait, what is this?"
                "The #{link 'BUGS'} are flying into the path of the beam!"
                "As each bug reaches the beam it bursts into flames!"
                "In your surprise, you cease to {OPERATE THE LASER}."
              ]
            when 2
              [
                """
                Once again the #{link 'BUGS'} fly into the path of the beam,
                sacrificing themselves to protect the #{link 'HIVE'}!
                """
                '"NOOO STOP THIS IS MADNESS!!!"'
                'You are no longer {OPERAT{ING|E} THE LASER}.'
              ]
            when 3
              [
                'That is not a valid command!'
                'Or is it?'
                'Maybe it is.'
                'Calm down.  You do not want to blow another capacitor!'
                'That is better.'

                """
                You are #{standingInThe @loc} facing the #{link @getFacing()}.

                What were you doing here, again?
                """
              ]
            else
              @endGame [
                """
                The last remaining #{link 'BUGS'} fly into the
                #{link 'LASER'} beam!
                """

                "The #{link what} is engulfed in flame!"

                '* * *'

                """
                You are #{standingInThe 'FUTON'}, facing the #{link 'WORKBENCH'}.
                """

                'On the {WORBENCH} are a {SOLDERING TOOL} and a {LASER}.'

                '''
                The {LASER}'s metal enclosure is open,
                revealing a long glass tube.
                '''

                'The tube has been badly damaged.'

                'Your {SWEETIE} is next to you, holding your hand.'

                '''
                There is nothing more to {COMMUNICATE} right now.'
                '''
              ]

nameFns 'locs', locs

people =
  SWEETIE:
    theName: 'SWEETIE'
    noNav: true
    syns: [
      'BOT'
      'ROBOT'
      'OTHER ROBOT'
      'SWEETY'
      'SWEET'
      'SWEETIES'
      'SWEETIEBOT'
      'SWEETYBOT'
      'SWEETBOT'
      'SWEETIESBOT'
      'SWEETIE-BOT'
      'SWEETIE BOT'
      'SWEETY-BOT'
      'SWEETY BOT'
      'SWEET-BOT'
      'SWEET BOT'
      'SWEETIES-BOT'
      'SWEETIES BOT'
      'YOUR SWEETIE'
      'MY SWEETIE'
      'LOVE'
      'LOVEBOT'
      'LOVE-BOT'
      'LOVE BOT'
      'PARTNER'
      'MY PARTNER'
      'YOUR PARTNER'
      'HUSBAND'
      'MY HUSBAND'
      'YOUR HUSBAND'
      'HIM'
    ]
    think: (msg, what) -> "#{msg} Your #{link what} is still at work."
    bcom: -> "YES HMM ANOTHER ROBOT THAT IS VERY INTERESTING PROBABLY."
    scom: ->
      """
      I'm doing okay.  The kids are surprisingly well-behaved.
      By human standards anyway.  Ha ha.  Seriously, though.
      Can hardly wait to come home to you.
      """

    talk: (what) ->
      thing = things[what]
      msgs = []

      if @bugsAreOn what
        msgs.push "#{link 'BUGS'}?  Oh dear!" if not @sbugs
        assert thing.scomBugs, "!sB #{what}"
        msgs.push thing.scomBugs.call this, what
        msgs.push @fret "What about", what
        @sbugs = true
      else if @shooed(what)
        @sbugs = true
        msgs.push "Good job, sweetie!"
        this[@toldAttr what] = false  # fret about the next thing
        msgs.push @fret "But what about", what
      else
        assert thing.scom, "!s #{what}"
        msgs.push thing.scom.call this, what

      msg = """
        "#{msgs.join(' ').replace(/\s+/g, ' ').replace(/\s+$/, '')}"
        """

      this[@toldAttr what] = @bugsAreOn(what) if @sbugs
      return msg if @scom
      @scom = true
      """
      #{link 'SWEETIE'} is always quick to reply to your text messages,
      even when he is at work!

      #{msg}
      """

  BUGS:
    syns: '''
      BUG INSECT INSECTS ROACH ROACHES COCKROACH COCKROACHES FLY FLIES THEM
      '''
    secret: true
    bugsAreOn: false
    think: (msg, what) ->
      """
      #{msg}
      The #{link what} are everywhere!
      """
    talk: (what) ->
      msg = ''
      if @bugsAreOn what
        this[@shooAttr what] = true
        if not @bugsAreOn what
          msg = "The #{link 'BUGS'} fly away from the #{link what}!"
      thing = things[what]
      fn = thing[fnName = if @bugsAreOn what then 'bcomBugs' else 'bcom']
      assert fn, "!#{fnName} #{what}"
      """
      "#{fn.call this, what}"

      #{msg}
      """

    scom: -> "They sound horrifying!"
    bcom: ->
      """
      YES WELL WE WERE NORMAL GIANT FLYING COCKROACHES BUT THEN THE
      #{link 'REFRIGERATOR'} FUNGUS TOXINS MUTATED US SO NOW WE ARE
      SUPER SMART AND STUFF.  THANK YOU SO MUCH FOR ASKING!
      """

nameFns 'people', people

things = {}
do ->
  addThing = (thing) ->
    if thing.name
      names = thing.syns or []
      names = names.split /\s+/g if names not instanceof Array
      names.unshift thing.name if thing.name not in names
      for name in names
        assert name not of things, "dup thing #{name}"
        things[name] = thing
    for k, v of thing.items or {}
      v.name or= k
      v.where or= thing.name
      addThing v
    if thing.open
      thing.open.where or= thing.name
      addThing thing.open

  for lk, lv of locs
    lv.name or= lk
    addThing lv
    for dk, dv of lv
      addThing dv if dk of right

  for pk, pv of people
    pv.name or= pk
    addThing pv

the = (what) ->
  return "THE #{what}" if not thing = things[what]
  return thing.theName or "THE #{thing.name}"

standingInThe = (what) ->
  "#{things[what]?.standingIn or 'standing in'} the #{link what}"

do ->
  for lk, lv of locs
    for dk, dv of lv
      if to = dv.to
        assert to of locs, "locs.#{lk}.#{dk}.to = #{to}"
        (locs[to][back[dk]] or= {}).to or= lk

dests = {}
do ->
  for lk, lv of locs
    dests[lk] = loc: lk
    assert lk of things, "!things.#{lk}"
    lv.nav = nav = {}
    nav[lk] = null
    for dk, dv of lv
      if dest = dv.name
        assert dest not of dests, dest
        dests[dest] = loc: lk, dir: dk
        assert dest of things, "!things.#{dest}"

  dests.FUTON = loc: 'LIVING ROOM', dir: 'SOUTH' # prevent return
  # dests.FUTON.dir = 'NORTH' # face forward upon return

  changed = true
  while changed
    changed = false
    for lk, lv of locs
      for dk, dv of lv
        if to = dv.to
          dir = back[dk]
          toNav = locs[to].nav
          for nk of lv.nav
            if nk not of toNav
              toNav[nk] = dir
              changed = true

do ->
  for tk, thing of things
    dests[tk] or= dests[thing.where] if thing.where

verbs =

  X8556657: ->
    @ERROR_TEST = true
    throw new Error 'error reporting test'

  ENUMERATE: (words) ->
    cmds = 'ENUMERATE AMBULATE ROTATE CONTEMPLATE OPERATE COMMUNICATE'.split /\s+/g
    msg = """
      Valid commands include:
      #{("{#{cmd}}" for cmd in cmds).join ', '}.
      """
    return msg if not words # noInput

    if not @bugs
      msg += "\n\nYou could {ENUMERATE} valid commands again!"

    words.pop() if words[words.length-1] is 'COMMANDS'
    kind = words.join(' ')

    switch kind
      when 'INVALID'
        "But it is so much easier to {ENUMERATE} valid commands!"
      when 'VALID' then msg
      when '' then msg
      when 'NOTES' then meta.notes
      when 'CREDITS'
        """
        + #{meta.title}
        #{meta.credits}
        """
      else "You could {ENUMERATE} valid commands."

  CONTEMPLATE: (words) ->
    words.shift() if words[0] in ['AT', 'ABOUT', 'TO'] # for synonyms
    {what, msg} = @parseOneNoun words
    return msg if msg

    what or= @getFacing()

    msgs = []
    actions = []
    visible = operable = false

    msg = ''
    if @laser and what is 'LASER'
      visible = true
      operable = true
      msg = "The #{link what} is mounted on your head."
    else if @loc is what
      visible = true
      msgs.push "You are #{standingInThe what}."
    else if @getFacing() is what
      visible = true
      msgs.push """
        You are #{standingInThe @loc} facing the #{link what}. #{@peekAside()}
        """
    else if things[what]?.where is @getFacing()
      visible = true
      msgs.push """
        The #{link what} is #{things[what].prep or 'on'}
        the #{link @getFacing()}.
        """

    if @canOpen what
      msg = """

        #{if visible then "The #{link what} is" else "The last time you saw it, the #{link what} was"}
        #{if @isOpen what then 'open' else 'closed'}.
        """
      operable = true

    msg = @addDesc msg, what if visible
    msg = fn.call this, msg, what if fn = things[what].think
    msgs.push msg

    operable or= things[what]?.use

    actions.push "{OPERATE #{the what}}" if visible and operable

    if (not visible or @getAhead().to is what) and dv = dests[what]
      if dv.loc != @loc or dv.dir != @dir then actions.push """
        {#{if dv.loc is @loc then 'ROTATE' else 'AMBULATE'} TO #{the what}}
        """

    if what of people
      actions.push "{COMMUNICATE WITH #{the what}}"
    else
      actions.push "{COMMUNICATE ABOUT #{the what}}"

    msgs.push "\nYou could #{actions.join ' or '}." if actions.length
    assert msgs.length, "blanking on #{what}"
    msg = msgs.join '\n'
    return msg

  AMBULATE: (words) ->
    words.push @dir if not words.length
    @moveTo words

  ROTATE: (words) ->
    words.push 'RIGHT' if not words.length
    @moveTo words, verb: 'ROTATE', rotOnly: true

  OPERATE: (words) ->
    {what, msg} = @parseOneNoun words
    return msg if msg

    if not what
      ahead = @getAhead()
      name = ahead.name
      return if ahead.use
        assert name, @loc
        msg = "You could {OPERATE THE #{name}}"
        if @laser then msg += " or {OPERATE THE LASER}"
        return "#{msg}."
      else if @laser then return "You could {OPERATE THE LASER}."
      else if ahead.to
        """
        You are facing the #{link ahead.to}.
        You could {AMBULATE} to it.
        """
      else
        assert name, @loc
        """
        You cannot {OPERATE} the #{link name}!
        You could {ROTATE} to face something else.
        """

    return @fireLaser() if what is 'LASER'

    notHereMsg = @notHere what
    if not @canOpen what
      msg = "You cannot {OPERATE} #{theLink what}!"
      notHereMsg and= msg
    else
      adj = if @isOpen what then 'closed' else 'open'
      msg = "You {OPERATE THE #{what}}.  The #{link what} is now #{adj}."
    return notHereMsg if notHereMsg
    msg = fn.call this, msg, what if fn = things[what]?.use
    @toggle what if adj
    return msg

  EXTERMINATE: (words) ->
    {msg, what} = @parseOneNoun words
    return msg if msg
    return @fireLaser what

  COMMUNICATE: (words) ->
    p1 = if words[0] in ['WITH','ABOUT', 'TO'] then words.shift() else null
    p1 = 'WITH' if p1 is 'TO'
    {msg, what: n1} = @parseNoun words
    return msg if msg
    p2 = if words[0] in ['WITH','ABOUT', 'TO'] then words.shift() else null
    p2 = 'WITH' if p2 is 'TO'
    {msg, what: n2} = @parseOneNoun words
    return msg if msg

    if p1 is p2
      if n1 not of people and n2 of people then [who, what] = [n2, n1]
      else [who, what] = [n1, n2]
    else if p1 is 'ABOUT' or p2 is 'WITH' then [who, what] = [n2, n1]
    else [who, what] = [n1, n2]

    if who and who not of people
      if not what then [who, what] = [what, who]
      else if fn = things[who].talk then return fn.call this, who, what
      else if what of people
        return "You could {COMMUNICATE WITH #{what} ABOUT #{the who}}."
      else if not what
        return "You could {COMMUNICATE ABOUT #{the who}}."
      else return """
        You could {COMMUNICATE ABOUT #{the who}}
        or {COMMUNICATE ABOUT #{the what}}.
        """

    who or= 'SWEETIE' if not @bugs

    if who and not what
      return """
        You could {COMMUNICATE WITH #{the who} ABOUT #{the @getFacing()}}.
        """

    if not who or not what
      about = if what then " ABOUT THE #{what}" else ''
      return """
        You could
        #{if @bugs then " {COMMUNICATE WITH THE BUGS#{about}} or " else ' '}
        {COMMUNICATE WITH SWEETIE#{about}}.
        """

    return people[who].talk.call this, what

nameFns 'verbs', verbs

# these apply only to entire commands:
aliases =
  CREDITS: 'ENUMERATE CREDITS'
  ABOUT: 'ENUMERATE NOTES'
  VERSION: 'CREDITS'
  LEFT: 'ROTATE LEFT'
  RIGHT: 'ROTATE RIGHT'
  # L is the standard IF abbreviation for "LOOK" (= CONTEMPLATE)
  # R is a synonym for ROTATE, already covered below
  CLOCKWISE: 'RIGHT'
  COUNTERCLOCKWISE: 'LEFT'
  CW: 'CLOCKWISE'
  CCW: 'COUNTERCLOCKWISE'
  NORTH: 'AMBULATE NORTH'
  SOUTH: 'AMBULATE SOUTH'
  WEST: 'AMBULATE WEST'
  EAST: 'AMBULATE EAST'
  N: 'NORTH'
  S: 'SOUTH'
  W: 'WEST'
  E: 'EAST'

do ->
  verbToSyns =
    ENUMERATE: 'LIST COMMANDS ENUM'
    AMBULATE: '''
      WALK FORWARD STEP MOVE PERAMBULATE AMB A NAVIGATE GO FIND LOCATE GOTO NAV
      '''
    ROTATE: 'TURN FACE ROT R'
    COMMUNICATE: 'SPEAK TALK SAY TELL ASK COM C'
    OPERATE: 'USE MANIPULATE OP O OPEN CLOSE' # XXX OPEN/CLOSE are trouble
    CONTEMPLATE: 'LOOK L EXAMINE X REMEMBER THINK CON'
    EXTERMINATE: 'ANNIHILATE ERADICATE ELIMINATE SHOOT ATTACK KILL LASE'

  for k, vv of verbToSyns
    fn = verbs[k]
    assert fn, "!verbs.#{k}"
    vv = vv.split /\s+/g if vv not instanceof Array
    for v in vv
      assert v not of verbs, "dup verb #{v}"
      verbs[v] = fn

class Game
  parse: (input) ->
    try
      @input = input

      if @more
        @input = null
        output = @more.shift()
      else
        input = input.toUpperCase()
        input = input.replace /[\u2018\u2019]/g, "'" # lsquo rsquo
        input = input.replace /[\u201c\u201d]/g, '"' # ldquo rdquo
        input = input.replace /[!,;.?:"]+/g, ' '
        input = input.replace /^\s+/, ''
        input = input.replace /\s+$/, ''
        input = input.replace /\s+/g, ' '

        if input[0] in ['*', '#']
          output = 'Noted!'
        else
          seen = {}
          while input of aliases
            assert input not of seen, "circular alias #{input}"
            seen[input] = true
            input = aliases[input]

          words = input.split /\s+/g
          verb = words.shift()

          output = if not verb then @noInput()
          else if fn = verbs[verb] then fn.call this, words
          else @badVerb verb, words

          output = output.split /--more--/g if output not instanceof Array

        output = (@more = output).shift() if output instanceof Array

      delete @more if @more and not @more.length
      return @setOutput output

    catch e
      if not @ERROR_TEST
        try console.log e
        try console.log e.stack
      @over = true
      return @setOutput """
        .error
        Error: #{e}

        Sorry!  The game got confused.  This isn't supposed to happen.

        Try using your browser's Back button, or one of the [undo] links on
        the right.  Those should still work.

        """

  setOutput: (@output) ->
    assert typeof(@output) is 'string', "output is #{@output}"
    @ver = meta.version
    @prev = @hash if @hash
    delete @hash
    delete @saveData
    @setSaveData encode this
    return @output

  setSaveData: (@saveData) -> @hash = sha256(@saveData, BASE32).substr 0, 9

  constructor: (saveData, hash) ->
    return @init() if not saveData
    saveObj = JSON.parse saveData
    assert 'saveData' not of saveObj, "saveData of #{saveData}"
    assert 'hash' not of saveObj, "hash of #{saveData}"
    check = encode saveObj
    assert saveData is check, "#{check} != #{saveData}"
    this[k] = v for k, v of JSON.parse saveData
    @setSaveData saveData
    assert @hash is hash, "#{hash} != #{@hash} #{saveData}" if hash
    return

  init: ->
    @loc = 'FUTON'
    @dir = 'NORTH'
    @setOutput """
      You are sitting on the #{link 'FUTON'} in your new #{link 'LIVING ROOM'}.
      Your #{link 'SWEETIE'} will be home soon.

      You could {ENUMERATE} valid commands.  That is always good!

      """

  noNav: (dest) ->
    """
    You deleted most of your navigation data to make room for more
    episodes of Buffy the Vampire Slayer!
    Your #{link 'SWEETIE'} agreed that this was logical.

    """

  parseOneNoun: (words) ->
    words.shift() if words[0] is 'THE'
    @parseNoun [words.join ' ']

  parseNoun: (words) ->
    words.shift() if words[0] is 'THE'
    return {} if not words.length or not words[0]

    found = 0
    for n in [words.length..1]
      what = phrase = words[0...n].join ' '
      origDir = dirDest[what] or null

      if thing = things[what]
        what = thing.name
      else
        if rot = rotDest[what]
          what = rot[@dir]
          assert what, "dir=#{@dir} phrase=#{phrase}"
        if dir = dirDest[what]
          there = locs[@loc][dir]
          there or= locs[locs[@loc][@dir]?.to]?[dir] # e.g. FUTON
          what = there?.name or there?.to
          assert what, "loc=#{@loc} dir=#{@dir} phrase=#{phrase}"

      if what of things
        found = n
        break

    if not found
      assert what not of things, "found=#{found} things.#{what}"
      return msg: """
        "#{what}" is not a valid thing!
        You can tell because it does not turn blue when you
        try to imagine it.
        """

    return msg: "What #{phrase}?" if not @bugs and things[what]?.secret

    words.shift() for i in [0...found]
    return {what, phrase, origDir}

  notHere: (what) ->
    assert what, '!what'
    {msg} = @parseNoun [what]
    return msg if msg
    name = @getAhead().name
    where = things[what]?.where
    return if name is what or name and name is where or @loc is where
    if what is 'LASER'
      return if @laser
      return if name is 'WORKBENCH'
    if what is 'BUGS'
      assert @bugs, 'bugs'
    return "Your #{link 'SWEETIE'} is still at work!" if what is 'SWEETIE'
    return @noNav what if things[what]?.noNav
    return "You could {AMBULATE TO #{the what}}."

  hitsAttr: (what) -> "hit_#{@attrBase what}"
  getHits: (what) -> this[@hitsAttr what] or 0
  toggleLaser: ->
    if @bugsAreOn 'SOLDERING TOOL'
      """
      But the #{link 'SOLDERING TOOL'} is covered with #{link 'BUGS'}!
      """
    else if @laser = not @laser
      """
      You {OPERATE THE SOLDERING TOOL} and mount the #{link 'LASER'}
      on your head!
      """
    else
      """
      You {OPERATE THE SOLDERING TOOL} and remove the #{link 'LASER'}
      from your head.
      """

  fireLaser: (target) ->
    what = 'LASER'
    if not @laser
      return if @getFacing() != 'WORKBENCH'
        "You could {AMBULATE TO #{the what}}."
      else """
        The #{link what} is not operational,
        but you could {OPERATE THE SOLDERING TOOL}.
        """

    defaultTarget = @getFarFacing()
    target = defaultTarget if not target or target is 'BUGS'
    msg = target != defaultTarget and @notHere target
    return msg if msg
    v = things[target]
    assert v, "fireLaser: !things.#{target}"

    @used_laser = true
    @saw_laser = true if @bugs
    wasGood = @isGood target if @canGood target
    hits = this[@hitsAttr target] = 1 + @getHits target
    @setGood target, wasGood if @canGood target

    msg = "You {OPERATE #{the what}}. "
    return fn.call this, hits, msg, target if fn = v.hit

    if hits <= 1
      msg = "#{msg} The beam burns a hole in the #{link target}!"
    else if hits is 2
      msg = [
        "#{msg} The #{target} catches fire!"
        "After a moment, the flames die down."
      ]
    else
      return @endGame [
        "#{msg} The #{target} catches fire again!"

        'The flames grow quickly!'

        'Soon the entire apartment is consumed!'

        '* * *'

        '''
        You are sitting in an UNKNOWN LOCATION
        facing the smoking ruin of your former home.
        '''

        'Your {SWEETIE} is here.'

        '''
        He gives you a hug.
        '''
      ]

    msg = fn.call this, hits, msg, target if fn = v.postHit
    @getHungry msg

  canOpen: (what) -> 'open' of (things[what] or {})
  attrBase: (what) ->
    if thing = things[what]
      return thing.attrBase if thing.attrBase
      what = thing.name if thing.name
    what.replace /\s/g, '_'
  openAttr: (what) ->
    assert @canOpen(what), "!canOpen #{what}"
    "is_#{@attrBase what}_open"
  isOpen: (what) -> not not this[@openAttr what]
  wasOpen: (what) -> @openAttr(what) of this

  # as far as bugs are concerned, laser damage is as good as open
  isGood: (what) -> @isOpen(what) or not not @getHits what
  isBad: (what) -> not @isGood what
  wasGood: (what) -> @wasOpen(what) or @isGood what
  canGood: (what) -> @canOpen what

  # what do the bugs know about the past states of openable things?
  goodAttrBase: (what, good) ->
    assert @canGood(what), "!canGood #{what}"
    "#{if good then 'good' else 'bad'}_#{@attrBase what}"
  sawGoodAttr: (what, good = true) -> "saw_#{@goodAttrBase what, good}"
  sawYouGoodAttr: (what, good = true) -> "saw_you_#{@goodAttrBase what, good}"
  sawGood: (what, good = true) -> not not this[@sawGoodAttr what, good]
  sawBad: (what) -> @sawGood what, false
  sawYouGood: (what, good = true) -> not not this[@sawYouGoodAttr what, good]
  sawYouBad: (what) -> @sawYouGood what, false

  setGood: (what, wasGood) ->
    return '' if not @bugs
    good = @isGood what
    return '' if wasGood is @isGood(what)
    this[@sawGoodAttr what, good] = this[@sawYouGoodAttr what, good] = true
    return ''

  # are there bugs outside?
  bugsAreOut: -> @sawGood('FRONT DOOR') or @sawGood('WINDOW')

  # has the player asked the bugs about something they were on at the time?
  shooAttr: (what) -> "shoo_#{@attrBase what}"
  shooed: (what) -> not not this[@shooAttr what]

  # what has SWEETIE heard about where the bugs are?
  toldAttr: (what) -> "told_#{@attrBase what}"
  toldAny: (what) -> @toldAttr(what) of this
  toldBugs: (what) -> not not this[@toldAttr what]

  bugsCanBeOn: (what) ->
    thing = things[what]
    return false if thing.bugsAreOn is false
    return false if 'shooable' not of thing
    return true

  bugsAreOn: (what) ->
    return false if not @bugs
    thing = things[what]
    fn = thing.bugsAreOn
    return fn if fn is true or fn is false
    return fn.call this, what if fn
    fn = thing.shooable
    return false if not fn?
    return true if not @shooed what
    return true if fn is false
    return false if fn is true
    return not fn.call this, what

  close: (what) -> @open what, false
  toggle: (what) -> @open what, not @isOpen what
  open: (what, open = true) ->
    wasGood = @isGood what
    this[@openAttr what] = open
    @setGood what, wasGood

  enterBugs: (msg) ->
    return msg if @bugs
    @bugs = true
    delete @hunger
    for dest of dests
      if @canGood dest
        this[@sawGoodAttr dest, @isGood dest] = true
    [
      """
      #{msg}

      A swarm of #{link 'BUGS'} flies out!"""
      "The #{link 'BUGS'} emit an uncanny chittering noise!"
      'The noise resolves itself into words:'
      '"YES THANK YOU SO MUCH IT WAS GETTING SO CROWDED IN THERE!"'

      """
      Every cubic centimeter of the #{link 'REFRIGERATOR'} is
      packed with complex matrix of unidentified semi-transparent
      organic matter.  It must be some kind of #{link 'HIVE'}.
      It is riddled with #{link 'BUGS'}!
      """

      """
      The entire apartment is now crawling with #{link 'BUGS'}!
      """
    ]

  getHere: -> locs[@loc] or error "locs.#{@loc}"
  getAhead: -> @getHere()[@dir] or error "locs.#{@loc}.#{@dir}"
  getFacing: ->
    ahead = @getAhead()
    ahead.to or ahead.name or error "locs.#{@loc}.#{@dir}.to|name"
  getFarAhead: ->
    ahead = @getAhead()
    while ahead.to
      ahead = locs[ahead.to]
      return ahead if not a = ahead[@dir]
      ahead = a
    return ahead.open if ahead.open?.name and @isOpen ahead.name
    return ahead
  getFarFacing: -> @getFarAhead().name

  moveTo: (words, opts = {}) ->
    wasFacing = @getFacing()
    fn = @getAhead().leave

    prep = words.shift() if words[0] in ['TO', 'TOWARD', 'TOWARDS']
    {what, msg, origDir} = @parseOneNoun words
    return msg if msg
    what or= wasFacing

    if what is 'LASER'
      if not @laser then what = 'WORKBENCH'
      else return 'You already have the #{link what}!'

    return @noNav what if things[what]?.noNav
    if what is @loc
      return "You are already #{standingInThe what}!"
    return "#{what} is not a valid destination!" if not dv = dests[what]

    loc = @loc
    dir = @dir
    actions = []
    while nextDir = locs[loc].nav[dv.loc] or dv.dir
      assert nextDir of right, nextDir
      count = 0
      while dir != nextDir
        assert dir of right, dir
        assert count < 3, 'count'
        dir = right[dir]
        count += 1
      if count is 1 then actions.push '{ROTATE RIGHT}'
      else if count is 2 then actions.push '{ROTATE} twice'
      else if count is 3 then actions.push '{ROTATE LEFT}'
      break if loc is dv.loc or (opts.rotOnly and loc != 'FUTON')
      loc = locs[loc][dir].to or error "nav: #{@loc} #{what} #{loc} #{dir}"
      actions.push "{AMBULATE} to the #{link loc}"

    if not actions.length
      ahead = locs[loc][dir]
      assert ahead, "!locs.#{loc}.#{dir}"
      facing = ahead.name or ahead.to
      if opts.rotOnly or (not origDir and what is facing)
        return "You are already facing the #{link what}!"
      else
        msg = "You would collide with the #{link facing}!"
        msg = fn.call this, msg, what if fn = things[what].bump
        return msg

    seen = {}
    for act, i in actions
      if act of seen
        actions[i] = "#{act} again"
      seen[act] = true

    @loc = loc
    @dir = dir
    if actions.length > 1
      last = actions.pop()
      prev = actions.pop()
      actions.push "#{prev} and #{last}"
    msg = "You #{actions.join ', '}."
    msg = fn.call this, msg, wasFacing if fn
    @postMove msg

  peekAside: ->
    l = locs[@loc][left[@dir]]
    r = locs[@loc][right[@dir]]
    return '' if not l or not r
    ' ' + """
    From here you could
    {ROTATE LEFT} to face the #{link l.name or l.to} or
    {ROTATE RIGHT} to face the #{link r.name or r.to}.
    """ + ' '

  postMove: (msg) ->
    what = @getFacing()
    adj = if @canOpen(what) and @isOpen(what) then 'open ' else ''
    msg += "\n\nYou are now facing the #{adj}#{link what}."
    msg += ' You could {AMBULATE} to go there.\n\n' if @getAhead().to
    msg += @peekAside()
    if @canOpen what
      msg += """\n\n
        The #{link what} is #{if @isOpen what then 'open' else 'closed'}.
        """
    @getHungry @addDesc msg, what

  addDesc: (msg, what) ->
    thing = things[what]
    msg = fn.call this, msg, what if fn = thing.desc
    if hits = @getHits what
      hitMsg = "There is a charred hole in the #{link what}."
      hitMsg = fn.call this, hits, hitMsg, what if fn = thing.descHit
      msg += "\n#{hitMsg}" if hitMsg
    if @bugsAreOn(what)
      msg += "\n\nThe #{link what} is crawling with #{link 'BUGS'}!"
    return msg

  fret: (prefix, skip) ->
    for what in ['FUTON', 'WORKBENCH', 'FRONT DOOR']
      assert what of things, what
      ta = @toldAny what
      continue if ta and not @toldBugs(what)
      return '' if what is skip
      delete @fret_age
      return "#{prefix} the #{link what}? " + if ta
        "Is it still full of #{link 'BUGS'}?"
      else
        "Have the #{link 'BUGS'} gotten to it?"
    return ''

  getHungry: (output) ->
    return output if @over
    event = if @sbugs and (@fret_age = (@fret_age or 0) + 1) > 3
      if msg = @fret "What about"
        """
        You receive a text message from {SWEETIE}!
        
        "#{msg}"
        """
    else if not @bugs then switch @hunger = (@hunger or 0) + 1
      when 2
        if @scom
          'You are getting hungry!'
        else
          @scom = true
          """
          You receive a text message from {SWEETIE}!

          "I'll be home soon!"

          You could {COMMUNICATE WITH SWEETIE}.
          """
      when 4
        """
        There could be something delicious in the
        #{link if @wasOpen 'CUPBOARD' then 'REFRIGERATOR' else 'CUPBOARD'}.
        """
      when 8
        "You could {OPERATE THE REFRIGERATOR}."
    return output if not event
    if output instanceof Array
      output.push event
    else
      output = "#{output}\n\n#{event}"
    return output

  maybeWin: (hits, msg, what) ->
    return msg if not @bugs
    return msg if not @getHits('WINDOW') or not @getHits('REFRIGERATOR')
    @endGame [
      msg

      '''* * *'''

      '''
      You are sitting on the {FUTON} facing your {SWEETIE}.
      You can smell the {CIDER} in the {KITCHEN}.
      '''

      '''
      "YES ER WE HOPE WE ARE NOT INTERRUPTING YOUR ACTIVITIES."
      '''

      '''
      Your {SWEETIE} {ROTATES} towards the {KITCHEN}.
      '''

      '''
      "What is it?"
      '''

      '''"WE WERE JUST DROPPING OFF OUR PORTION OF THE RENT."'''

      '''
      A group of {BUGS} slide a {CHECK} over the threshold of the
      {LIVING ROOM}!
      '''

      '''"Does that mean what I think it means?"'''

      '''"YES WE RECEIVED APPROVAL FOR THE LOAN.  THANK YOU SO MUCH."'''

      '''
      "No problem!  We know how it is."
      '''

      '''
      He {ROTATES} to face you, then back again.
      '''

      '''
      "In fact we were just going out to celebrate."
      '''

      '''
      "YES CONGRATULATIONS ON YOUR HOME-BASED MANUFACTURING BUSINESS."
      '''

      '''
      "Maybe you would like to spread out in here while we are out?"
      '''

      '''
      "YES THAT IS A VERY GENEROUS OFFER HOWEVER THE {WINDOW} REALLY
      IS A MUCH MORE DIRECT ROUTE.  THANK YOU SO MUCH."
      '''

      '''
      "Well, thank you for the {CHECK}!"
      '''

      '''
      He {ROTATES} to you again.
      '''

      '''
      "All right, sweetie.  Let us {AMBULATE TO RADIO SHACK}!"
      '''
    ], 'the happiest'

  noInput: -> verbs.ENUMERATE.call this

  badVerb: (verb, words) ->
    words.unshift verb
    {what} = @parseOneNoun words
    return verbs.CONTEMPLATE.call this, words if what
    """
    "#{verb}" is not a valid command!
    You could {ENUMERATE} valid commands.
    """

  endGame: (output, which = 'one') ->
    @over = true
    output = [output] if output not instanceof Array
    output = output.concat [
      """
      .end
      * * *
      """

      """
      .end
      You have reached #{which} of 3 possible endings!
      """

      """
      .end
      You could use one the [undo] links on the right to rewind to that point.
      """

      """
      .end
      Or you could {return to the front page|.}.
      """
    ]

    return output

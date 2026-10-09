# Reading script - batch 1

About 100 training lines, roughly ten minutes of speech: the first dose. Later
batches add to it, so ids never change once recorded.

Format: `id | text` under a `## category` heading. A heading containing
`held-out` keeps its lines out of training. `free talk` lines are prompts, not
text to read; Whisper writes their transcript. Numbers are spelled out so the
read-accuracy check compares like with like.

## statements

st01 | I spent most of the morning untangling a build that had been broken since Friday.
st02 | The coffee machine on our floor has been out of order for three weeks now.
st03 | We moved the meeting to Thursday, because half the team was out on leave.
st04 | My grandfather kept every receipt he ever got, in shoeboxes under the bed.
st05 | The rain finally came through in the afternoon, and the whole city slowed down.
st06 | I think the simplest fix is usually the right one, even if it feels boring.
st07 | She drove all the way to the coast just to watch the sun come up over the water.
st08 | There's a little bakery near my house that sells the best rusks I've ever had.
st09 | Nobody noticed the alarm for an hour, which tells you something about the alarm.
st10 | The dog next door barks at every single delivery van that comes down the street.
st11 | We tried three different approaches before one of them actually stuck.
st12 | It took me years to learn that asking for help is not the same as giving up.
st13 | The report is due on Friday, and I've barely started on the second section.
st14 | I read the whole book in one sitting and then immediately wanted to read it again.
st15 | The new release went out at midnight without a single complaint.
st16 | My first car was a little white Toyota with no aircon and a broken radio.
st17 | Every Sunday we used to have a braai at my uncle's place on the farm.
st18 | The trick is to write the test first, so you know what done looks like.
st19 | That road floods every summer, and every summer someone tries to drive through it.
st20 | I'll be honest, I didn't expect the demo to go nearly as well as it did.
st21 | We ended up rewriting the whole thing from scratch, and it was worth it.
st22 | The mountain looked close enough to touch, but it took us four hours to reach it.
st23 | My phone died halfway through the call, right at the important part.
st24 | Most of the work happens long before anyone sees the final result.
st25 | The kids built a fort out of every cushion in the house and refused to take it down.

## questions

qu01 | Have you had a chance to look at the pull request I sent you yesterday?
qu02 | Do you want to grab lunch after the stand-up, or are you slammed today?
qu03 | Why does the build only ever break on a Friday afternoon?
qu04 | What would you do differently if you had to start the project over?
qu05 | Is it just me, or is it way colder in the office than it was last week?
qu06 | Can you remind me which branch we agreed to deploy from?
qu07 | How long do you think it'll take to get the new service into production?
qu08 | Did anyone actually read the release notes before we shipped?
qu09 | Where did you put the spare keys for the storeroom?
qu10 | Would it be easier if I just walked you through it on a call?
qu11 | Are we still on for the team dinner on Thursday night?
qu12 | Who decided that a meeting at seven in the morning was a good idea?
qu13 | The tests are passing now after the restart, aren't they?
qu14 | You're coming to the braai on Saturday, right?

## lists and pauses

li01 | For the trip we need water, sunscreen, two hats, a map, and something for the kids to eat.
li02 | The plan is simple: build it, test it, ship it, and then go home early.
li03 | I checked the logs; nothing. I checked the metrics; nothing. Then I checked the config, and there it was.
li04 | We've got three options, really: wait for the vendor, patch it ourselves, or turn the feature off.
li05 | First you open the settings, then you pick your repos, and then you set how often it should poll.
li06 | Bread, milk, eggs, coffee; and if they have it, a bag of biltong for the road.
li07 | The service reads the event, checks the balance, writes the transfer, and publishes the result.
li08 | It was late, it was raining, and the only open shop was a petrol station on the highway.
li09 | Monday was planning; Tuesday was meetings; by Wednesday I finally got to write some code.
li10 | Red, orange, yellow, green, blue, indigo and violet, in that order, every single time.
li11 | We kept the good parts, threw out the rest, and wrote down why, so nobody has to ask again.
li12 | My list for the weekend is short: sleep in, fix the gate, and watch the rugby.
li13 | If it's slow, check the database; if it's wrong, check the cache; if it's both, check your assumptions.
li14 | The house had a long passage, a tiny kitchen, two bedrooms, and a garden full of lemon trees.
li15 | Take the second left, go past the school, and it's the blue house on the corner.
li16 | The migration, which we'd tested twice (three times, actually), still found a way to surprise us.

## short lines

sh01 | That's it, we're done for the day.
sh02 | Nope, not today, try again tomorrow.
sh03 | Right, let's get this thing started.
sh04 | Honestly, that went better than expected.
sh05 | Okay, looks good to me, ship it.
sh06 | Give me five minutes and I'll be there.
sh07 | Well, that escalated quickly.
sh08 | Good morning, everyone, let's get going.
sh09 | Not bad at all for a first attempt.
sh10 | Hang on, let me check that again.

## long sentences

lo01 | So what happened was, we deployed the fix on Tuesday, everything looked fine for about two hours, and then the alerts started coming in one after the other until the whole channel was just red.
lo02 | When I was a kid we used to drive up to my grandparents every December, eight hours in the back of the car with no aircon, and somehow those are still some of my favourite memories.
lo03 | The thing about a good dashboard is that it doesn't just show you numbers, it shows you what needs your attention right now, and it gets out of the way when nothing does.
lo04 | I started reading the documentation thinking it would take ten minutes, and three hours later I was deep in an old forum thread with no idea how I got there.
lo05 | If you've never watched a storm roll in over the Highveld in the late afternoon, with the sky going purple and the wind picking up the dust, you really should, at least once.
lo06 | We spent the first week arguing about the architecture, the second week building the wrong thing, and the third week building the right thing in half the time.
lo07 | My advice to anyone starting out is to read other people's code as much as you write your own, because that's where you pick up the habits nobody writes down.
lo08 | By the time we found the bug it had been in production for months, quietly rounding every amount down by a cent, and nobody had noticed because nobody looked.
lo09 | She told the story so well that by the end the whole table had gone quiet, and even the waiter had stopped to listen.
lo10 | The plan for the weekend was to rest, but somehow it turned into painting the spare room, fixing the gate, and driving across town twice for a part that didn't fit.

## technical

te01 | The consumer reads from the Kafka topic and writes the result to Postgres.
te02 | We cache the session in Valkey so the login doesn't hit the database every time.
te03 | The analytics queries run on ClickHouse, which is ridiculously fast for this kind of thing.
te04 | Open a pull request against main, tag a reviewer, and wait for the checks to go green.
te05 | The pod kept restarting, so I pulled the logs with kubectl and found an out of memory error.
te06 | We use gRPC between the services and protobuf for the message contracts.
te07 | Argo picked up the change and rolled it out to staging in about two minutes.
te08 | The pipeline builds the container image, scans it with Trivy, and pushes it to the registry.
te09 | Keycloak handles the sign in, and the token carries the roles the service checks.
te10 | I wrote a quick script with the GitHub CLI to list every issue assigned to me.
te11 | The ledger has to balance to the cent, so we never use floating point for money.
te12 | OpenTelemetry sends the traces to Grafana, and that's where you go when something's slow.

## south african english

af01 | Jip, I'll sort it out now now, just let me finish this first.
af02 | That braai was lekker, we should do it again before the end of the month.
af03 | Ag no man, the robot at the corner is out again and the traffic is a mess.
af04 | Shame, he's been sick the whole week and still came in for the demo.
af05 | Is it? I didn't know they moved the whole team to the other building.
af06 | Eish, the load shedding schedule changed again and my laptop's on five percent.
af07 | Howzit everyone, sorry I'm late, the traffic on the highway was hectic.
af08 | Just now I'll send you the link, I'm still busy with something.

## storytelling

sy01 | Once upon a time, in a village at the edge of a very dark forest, there lived a girl who was afraid of nothing at all.
sy02 | And then, just as he reached for the door, the lights went out.
sy03 | "Who's there?" she whispered, but the only answer was the wind.
sy04 | The old man smiled, leaned back in his chair, and said, "Let me tell you how it really happened."
sy05 | They ran as fast as they could, through the long grass and over the river, and they didn't stop until they reached the hill.
sy06 | For three days the ship drifted, and on the fourth morning someone finally shouted, "Land!"
sy07 | The dragon opened one enormous eye, looked at the little knight, and yawned.
sy08 | And that, my friends, is why you never leave the gate open on a farm.

## free talk

ft01 | Talk about what you did last weekend.
ft02 | Explain to a new colleague how you like to start your workday.
ft03 | Describe your favourite place to go when you need a break.
ft04 | Tell the story of a bug that cost you a whole day.
ft05 | Talk about a book you read as a kid that stuck with you.
ft06 | Explain how a braai should be done properly, to someone who has never been to one.
ft07 | Talk about the best trip you have ever taken.

## held-out statements

ho01 | The train was late again, so I walked the last two kilometres in the rain.
ho02 | We finally finished the migration on Wednesday night, just before midnight.
ho03 | My mother still phones every Sunday to ask if I'm eating properly.
ho04 | The best ideas usually show up when you stop staring at the problem.
ho05 | That old bridge has been closed for repairs for as long as I can remember.
ho06 | I keep a notebook on my desk for the things I'll forget by lunchtime.
ho07 | The office was completely empty by the time I looked up from my screen.
ho08 | Our neighbours have a cat that thinks our garden belongs to it.
ho09 | It turned out the problem was a single missing comma in the config file.
ho10 | We drove back home in silence, too tired to say anything at all.

## held-out questions

ho11 | Did you remember to switch off the geyser before we left?
ho12 | What time does the shop on the corner close on a Saturday?
ho13 | Can we push the review to tomorrow morning instead?
ho14 | Have you ever seen the sea from the top of Table Mountain?
ho15 | Why is the printer always out of paper when I actually need it?

## held-out long sentences

ho16 | If the weather holds, we'll leave early, stop for breakfast on the way, and be at the cottage by lunch.
ho17 | The new system is faster, simpler, and cheaper to run, which is not something you get to say very often.
ho18 | After the third failed deploy, we stopped, made some coffee, and read the error message properly for the first time.
ho19 | She packed her bags, said goodbye to everyone at the office, and left for the airport without looking back.
ho20 | When the power came back on, the fridge started humming, the dog started barking, and the kids cheered from the lounge.

require 'rubygems'
require 'watir'

$dicebalance=0
$dicenewbalance=0
class Gamblor
  
  Mainpage = Watir::Browser.new :ff
  # DOGE DOGE DOGE DOGE DOGE DOGE
  # ___   ___   ___ ___ 
  #|   \ / _ \ / __| __|
  #| |) | (_) | (_ | _| 
  #|___/ \___/ \___|___|
  #
  # DOGE DOGE DOGE DOGE DOGE DOGE
  #--------------------------------------------------------------------
  Basewager=0.028           #Average amount bet per game
  Variance =0.001           #Max variance in bets in either direction
  Max_round=18              #Most loses in a row considered acceptable
  Runs     =5000000         #Number of times this shit is attempted
  Panic_mode=1              #1=abort when over max_round  #0=restart when over max_round
  #--------------------------------------------------------------------
  IncreasedRiskMode=true    #Here goes, a new, terrifying mode
  Risk_Starting=2           #Payout multiplier on the first roll
  Risk_RoundsToDecrease=1   #Rounds taken to reduce the risk
  Risk_AmountToDecrease=1   #Payout multiplier reduction per ^ rounds
  #--------------------------------------------------------------------
  SafeLaterBetMode=false     
  SafeWagerCutoff=10         #At this point we stop trying to make a profit and just aim to recoop losses
  #--------------------------------------------------------------------
  ##puts ("%.8f" %variable) - 8 decimal places output 
  
  def init
    Mainpage.goto "https://doge-dice.com/"
    sleep(8)
    Mainpage.link(:title, "Close").click
    Mainpage.link(:text, "Account").click
    sleep(1)
    Mainpage.text_field(:id, "myuser").set("        ")#PUT USERNAME AND PASSWORD
    Mainpage.text_field(:id, "mypass").set("        ")#IN HERE
    Mainpage.button(:value,"login").click
    sleep(10)
    Mainpage.text_field(:id, "pct_payout").set("2")
    Mainpage.text_field(:id, "pct_bet").set("1")
    $dicebalance=0
  end
  
  def riskManagement(rounds)
    payout=Risk_Starting-((rounds/Risk_RoundsToDecrease).to_i)*Risk_AmountToDecrease
    if payout<2
      payout=2
    end
    puts(payout.to_s+"x should be the current payout")
    Mainpage.text_field(:id, "pct_payout").set(payout)
  end
  
  def safeBet(rounds,wager,startwager)
    puts "Now reducing bet and accepting a lack of money, old bet: " + wager.to_s
    wager = (startwager*(2**rounds))-startwager*(rounds-SafeWagerCutoff+1)
    puts "And the new, less risky but no profit bet should be: " + wager.to_s
    #sleep(20)
    return(wager)
  end
  
  def getStats()
    $profit=$dicenewbalance-1000
    $overallprofit = Mainpage.span(:class, "myprofit").text
    $invest = Mainpage.span(:class, "investment").text
    $investprofit = Mainpage.span(:class, "invest_pft").text
  end
  
  def getStats2()
    puts Mainpage.span(:class, "myprofit").text
    puts Mainpage.span(:class, "investment").value
    puts Mainpage.span(:class, "invest_pft").value
  end

  def gamble
    x = 0
    
    while x<Runs
      random=rand(1000)
      sleep(random/2000)
      if(random>990)
        sleep(5+random/100)
      end
      rounds=0
      #Randomises the starting bet to reduce possibility of detection
      startwager = Basewager - Variance
      startwager+= (Variance*rand(20).to_f/10).round(8);
      puts startwager.to_s + "Is our starting wager hopefully"
      #Gets our current money before we start betting
      $dicebalance = Mainpage.text_field(:id, "pct_balance").value
      #$dicebalance[0]=''   #Should take out the first character but no need here
      $dicebalance = $dicebalance.to_f
      puts $dicebalance.to_s + " is your starting balance"
      getStats()
      while rounds<Max_round
        random=rand(1000)
        sleep(random/4000)
        wager = startwager*(2**rounds)
        puts wager.to_s + " is the wager this round"
        
        if (SafeLaterBetMode==true) && (rounds>=SafeWagerCutoff)
          wager=safeBet(rounds,wager,startwager)
        end
        
        Mainpage.text_field(:id, "pct_bet").set("%.8f" % wager)
        #Wager Set
        
        #Payout manager
        if IncreasedRiskMode
          riskManagement(rounds)
        end
        
        Mainpage.button(:id, "a_hi").click
        #Bet Complete
        
        #Check the bet went through
        sleep(random/4000)
        match_checks=0
        $diceprevbalance = $dicenewbalance
        $dicenewbalance = Mainpage.text_field(:id, "pct_balance").value.to_f
        while ($diceprevbalance == $dicenewbalance) && (match_checks<15)
          puts "Doesn't seem like it's bet succesfully, checking " + match_checks.to_s + " times out of 15"
          sleep(0.1+match_checks/2+random/2000)
          match_checks+=1
          $dicenewbalance = Mainpage.text_field(:id, "pct_balance").value.to_f
          puts "Currently the two values are at: " + $diceprevbalance.to_s + " for before this bet and " + $dicenewbalance.to_s + " for after it."
        end
        if match_checks>=15
          #The problem still isn't resolved, maybe bet again?
          #Right now we abort.
          puts"Okay there might be something wrong here, refreshing page"
          Mainpage.refresh
          #init()
          sleep(5)
          $dicenewbalance = Mainpage.text_field(:id, "pct_balance").value.to_f
          puts"Whatever happens now it should be okay, if the bet wasn't placed it will be this time."
        end
        if match_checks>0
          #We had a small problem
          puts "Lag may have occured"
        end
        
        #### Print results
        puts "Results:" + $dicenewbalance.to_s + "(New) vs. " + $diceprevbalance.to_s + "(Previous) vs. " + $dicebalance.to_s + "(Starting)"
        ##### Compare results
        if $dicebalance>$dicenewbalance
          #WE LOST
          puts "LOSER"
          rounds+=1
          if((rounds>=Max_round) && (Panic_mode==1))
            x=99999999999999999
            puts "PANIC MODE!!"
          end
        end
        if $dicebalance<$dicenewbalance
          #WE WON
          puts "WON"
          rounds=99999999999999
        end
#        if $dicebalance==$dicenewbalance
#          #WE BROKE IT
#          puts "Same balance-DOUBLE FUCKIGN CHECK"
#          sleep(30+random/1000)
#          $dicenewbalance = Mainpage.text_field(:id, "pct_balance").value
#          $dicenewbalance = $dicenewbalance.to_f
#          puts $dicenewbalance.to_s + "(new) vs. " + $dicebalance.to_s + "(old)"
#          if $dicebalance>$dicenewbalance
#            #WE LOST
#            puts "LOSER"
#            rounds+=1
#            if(rounds>=Max_round && Panic_mode)
#              x=99999999999999999
#              puts "PANIC MODE!!"
#            end
#          end
#          if $dicebalance<$dicenewbalance
#            #WE WON
#            puts "WON"
#            rounds=99999999999999
#          end
#          if $dicebalance==$dicenewbalance
#            puts "OKAY YEAH SOMETHING IS WRONG"
#            rounds=999999999999999
#            x=9999999999999
#          end
#        end
      end
      x+=1
    end
  end
end

#gamblebot=Gamblor.new
#gamblebot.init
#gamblebot.gamble

if [ "$Email" == "" ]; then
	echo "lost email address!"
	exit 0
fi

if $IsIntegrationTestingTask -eq "true" ; then
	echo "start Integration testing..."
	sendemail -f "$Email" -t "$Email" -u "WebexSDK build by Travis" -m "BranchName=$TRAVIS_BRANCH\nBuildNumber=$TRAVIS_JOB_ID\nPullRequestNumber=$TRAVIS_PULL_REQUEST" -s smtp.gmail.com -o tls=yes -xu "$Email" -xp "$EmailPWD"
else
	echo "not the integration test task return normal..."
	exit 0
fi
done
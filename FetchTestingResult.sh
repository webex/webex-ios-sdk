for ((i=0; i<=25; i++)); do
buildEmailTitle=`curl -u $Email:$EmailPWD --silent "https://mail.google.com/mail/feed/atom/important" | awk -F '<title>' '{for (i=3; i<=NF; i++) {print $i"\n"}}' | awk -F '</title>' '{for (i=1; i<=NF; i=i+2) {print $i"\n"}}' | awk -F: '/^BuildNumber:'"$TRAVIS_JOB_ID"'/'`

if [ $i -eq "24" ] ; then
	echo "Integration testing : TIMEOUT!"
	exit 0
fi

echo "$buildEmailTitle"
if [ "$buildEmailTitle" == "" ]; then
	#wait
	echo "wait 60 sec"
	sleep 60
else
	buildResult=`echo | awk '{print test}' test="$buildEmailTitle" | awk -F: '/Fixed/||/Successful/'`
	#echo "$buildResult"
	if [ "$buildResult" == "" ]; then
		#build failed
		echo "$buildEmailTitle"
		exit 1
	else
		echo "Jenkins build Successful!"
		exit 0
	fi
fi
done
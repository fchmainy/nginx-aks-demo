<HTML>
	<body style="background-color:black;">
		<HEAD>
			<title>Random Name Generator</title>
			<style type="text/css">
            body {
                position: relative;
                height: 100vh;
                margin: 0;
                }

            h1 {
                position: absolute;
                top: 50%;
                transform: translateY(-50%);
                width: 100%;
                text-align: center;
                margin: 0;
                }
        </style>
		</HEAD>
		<BODY>
			<?php
				$url="http://apigw.apigw.svc.cluster.local/name";
				$ch = curl_init();
				curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
				curl_setopt($ch, CURLOPT_URL,$url);
				$result=curl_exec($ch);
				curl_close($ch);
				$generated_name=json_decode($result, true);
				echo '<h1 style="font-family:Courier; color:green;">'.$generated_name['adjectives'].' '.$generated_name['animals'].' of the '.$generated_name['colors'].' '.$generated_name['locations'].'</h1>';
			?>
		</BODY>
	</HTML>

 <HTML>
                <HEAD>
<!-- Google Tag Manager -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','<?php echo getenv('GOOGLETAGID'); ?>');</script>
<!-- End Google Tag Manager -->

                        <title>Random Name Generator</title>
                        <script src="./vendor/jquery/jquery-3.2.1.min.js"></script>
			<script src="./js/script.js"></script>
			<style>
				body {
 					background: url('./images/background.jpg');
 					background-repeat: no-repeat;
        			}
			</style>
			<link rel="stylesheet" href="./css/style.css" />
                </HEAD>
                <BODY>
                    <div id="adjective-popup">
                        <form class="word-form" action="" id="adjective-form" method="post" enctype="application/json">
                            <h2>Add an adjective</h2>
                            <div>
                                <div>
                                    <label>Adjective: </label><span id="adjective-info" class="info"></span>
                                </div>
                                <div>
                                    <input type="text" id="adjective" name="adjective" class="inputBox" />
                                </div>
                            </div>
                            <div>
                                <input type="submit" id="send" name="send" value="Send" />
                            </div>
                        </form>
                    </div>
                    <div id="animal-popup">
                        <form class="word-form" action="" id="animal-form" method="post" enctype="application/json">
                            <h2>Add an animal</h2>
                            <div>
                                <div>
                                    <label>Animal: </label><span id="animal-info" class="info"></span>
                                </div>
                                <div>
                                    <input type="text" id="animal" name="animal" class="inputBox" />
                                </div>
                            </div>
                            <div>
                                <input type="submit" id="send" name="send" value="Send" />
                            </div>
                        </form>
                    </div>
                    <div id="color-popup">
                        <form class="word-form" action="" id="color-form" method="post" enctype="application/json">
                            <h2>Add an color</h2>
                            <div>
                                <div>
                                    <label>Color: </label><span id="color-info" class="info"></span>
                                </div>
                                <div>
                                    <input type="text" id="color" name="color" class="inputBox" />
                                </div>
                            </div>
                            <div>
                                <input type="submit" id="send" name="send" value="Send" />
                            </div>
                        </form>
                    </div>
                    <div id="location-popup">
                        <form class="word-form" action="" id="location-form" method="post" enctype="application/json">
                            <h2>Add a location</h2>
                            <div>
                                <div>
                                    <label>Location: </label><span id="location-info" class="info"></span>
                                </div>
                                <div>
                                    <input type="text" id="location" name="location" class="inputBox" />
                                </div>
                            </div>
                            <div>
                                <input type="submit" id="send" name="send" value="Send" />
                            </div>
                        </form>
                    </div>

                    <table class="center" style="height: 72px;" width="800">
                                <tbody>
                                <tr>
                                <td style="width: 158px;"><img src="./images/shape.png" alt="" /></td>
                                <td style="width: 159px;"><img src="./images/f5nginx.png" alt="" /></td>
                                <td style="width: 159px;"><img src="./images/volterra.png" alt="" /></td>
                                </tr>
                                </tbody>
                    </table>
		    <table style="height: 300px;" width="800">
		    <tr></tr>
                    </table>
                    <table class="center" style="background: linear-gradient(to top left, DimGray, transparent 95%); border-radius: 15px 50px;" width="800">
                    <tbody>
                                <tr>
                    <?php
                                $NS = getenv('NAMESPACE');
                                $url='http://generator.'.$NS.'/name';
                                $ch = curl_init();
                                curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                                curl_setopt($ch, CURLOPT_URL,$url);
                                $result=curl_exec($ch);
                                curl_close($ch);
                                $generated_name=json_decode($result, true);
                                #echo '<td>';
                                echo '<td><div style="font-family:Courier; text-align:center; color:green; font-size: 32; font-weight: bold;">'.$generated_name['adjectives'].'</div></td>';
                                echo '<td><div style="font-family:Courier; text-align:center; color:green; font-size: 32; font-weight: bold;">'.$generated_name['animals'].'</div></td>';
                                echo '<td><div style="font-family:Courier; text-align:center; color:green; font-size: 32; font-weight: bold;"> of the </div></td>';
				echo '<td><div style="font-family:Courier; text-align:center; color:green; font-size: 32; font-weight: bold;">'.$generated_name['colors'].'</div></td>';
                                echo '<td><div style="font-family:Courier; text-align:center; color:green; font-size: 32; font-weight: bold;">'.$generated_name['locations'].'</div></td>';

				echo "<script>console.log(".json_encode($_POST).")</script>";
				if (! empty($_POST["send"])) {
					if (! empty($_POST["adjective"])) {
						$word = filter_var($_POST["adjective"], FILTER_SANITIZE_STRING);
						$postURL='http://adjectives.'.$NS.'/adjectives';
						$payload = json_encode(array("name" => $word));
					}
					if (! empty($_POST["animal"])) {
						$word = filter_var($_POST["animal"], FILTER_SANITIZE_STRING);
						echo '<script>console.log("error: '.$word.'");</script>';
						$postURL='http://animals.'.$NS.'/animals';
						echo '<script>console.log("error: '.$postURL.'");</script>';
                                                $payload = json_encode(array( "name" => $word));
					}
					if (! empty($_POST["color"])) {
						$word = filter_var($_POST["color"], FILTER_SANITIZE_STRING);
                                                $postURL='http://colors.'.$NS.'/colors';
                                                $payload = json_encode(array( "name" => $word));
					}
					if (! empty($_POST["location"])) {
						$word = filter_var($_POST["location"], FILTER_SANITIZE_STRING);
                                                $postURL='http://locations.'.$NS.'/locations';
                                                $payload = json_encode(array( "name" => $word));
					}
					$ch2 = curl_init();
					curl_setopt($ch2, CURLOPT_RETURNTRANSFER, true);
					curl_setopt($ch2, CURLOPT_VERBOSE, true);
					curl_setopt($ch2, CURLOPT_URL, $postURL);
					curl_setopt($ch2, CURLOPT_POSTFIELDS, $payload);
					curl_setopt($ch2, CURLOPT_HTTPHEADER, array('Content-Type: application/json'));
					#echo '<script>console.log("curl opts: '.$ch2.'");</script>';
					$res=curl_exec($ch2);
					$curl_info = json_encode(curl_getinfo($ch2));
					$curl_error = json_encode(curl_error($ch2));
					#echo '<script>console.log("error: '.$curl_error.'");</script>';
					#echo '<script>console.log("info: '.$curl_info.'");</script>';
					#echo '<script>console.log("res: '.$res.'");</script>';
                                	curl_close($ch2);

					echo '<div id="success">Your new word '.$word.' as been successfully posted!</div>';
				}
                    ?>
                                </tr>
                                <tr>
                                <td align=center><div id="plus-adjective-icon"><img src="./icon/plus.png" width="50" height="50" alt="" /></div></td>
                                <td align=center><div id="plus-animal-icon"><img src="./icon/plus.png" width="50" height="50" alt="" /></div></td>
				<td align=center><div></div></td>
                                <td align=center><div id="plus-color-icon"><img src="./icon/plus.png" width="50" height="50" alt="" /></div></td>
                                <td align=center><div id="plus-location-icon"><img src="./icon/plus.png" width="50" height="50" alt="Add a location to the API" /></div></td>
                                </tr>
                    </tbody>
                    </table>
            	</BODY>
</HTML>

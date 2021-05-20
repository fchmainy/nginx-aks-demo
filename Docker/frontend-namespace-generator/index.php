<HTML>
        <body style="background-color:black;">
                <HEAD>
                        <!-- Google Tag Manager -->
                        <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
                        new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
                        j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
                        'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
                        })(window,document,'script','dataLayer','<?php echo getenv('GOOGLETAGID'); ?>');</script>
                        <!-- End Google Tag Manager -->
                        <title>Random Name Generator</title>
                        <style>
                                body {
                                background-image: url("./images/background.jpeg");
                                }
                        </style>
                        <style type="text/css">
                        body {
                                position: relative;
                                height: 100vh;
                                margin: 0;
                                }

                        h1 {
                                position: absolute;
                                text-align: center;
                                top: 65%;
                                left: 50%;
                                margin-right: -50%;
                                transform: translate(-50%);
                                border-radius: 15px 50px;
                                background: linear-gradient(to top left, DimGray, transparent 95%);
                                padding: 15px;
                                width: 700px;
                                height: 50px;
                                justify-content: center;
                        </style>
                </HEAD>
                <BODY>
                        <table style="height: 72px;" width="498">
                                <tbody>
                                <tr>
                                <td style="width: 158px;"><img src="./images/shape.png" alt="" /></td>
                                <td style="width: 159px;"><img src="./images/f5nginx.png" alt="" /></td>
                                <td style="width: 159px;"><img src="./images/volterra.png" alt="" /></td>
                                </tr>
                                </tbody>
                        </table>
                        <?php
                                $NS = getenv('NAMESPACE');
                                $url='http://generator.'.$NS.'/name';
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

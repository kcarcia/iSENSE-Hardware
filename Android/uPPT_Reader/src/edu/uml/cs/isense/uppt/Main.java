/***************************************************************************************************/
/***************************************************************************************************/
/**                                                                                               **/
/**      IIIIIIIIIIIII               iSENSE uPPT Reader App                      SSSSSSSSS        **/
/**           III                                                               SSS               **/
/**           III                    By: Michael Stowell,                      SSS                **/
/**           III                        Jeremy Poulin,                         SSS               **/
/**           III                        Nick Ver Voort                          SSSSSSSSS        **/
/**           III                    Faculty Advisor:  Fred Martin                      SSS       **/
/**           III                    Group:            ECG,                              SSS      **/
/**           III                                      iSENSE                           SSS       **/
/**      IIIIIIIIIIIII               Property:         UMass Lowell              SSSSSSSSS        **/
/**                                                                                               **/
/***************************************************************************************************/
/***************************************************************************************************/

package edu.uml.cs.isense.uppt;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.LinkedList;

import org.json.JSONArray;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.ConnectivityManager;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Bundle;
import android.os.Environment;
import android.os.Vibrator;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.MotionEvent;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.CheckedTextView;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import edu.uml.cs.isense.comm.RestAPI;
import edu.uml.cs.isense.supplements.ObscuredSharedPreferences;
import edu.uml.cs.isense.uppt.SimpleGestureFilter.SimpleGestureListener;
import edu.uml.cs.isense.waffle.Waffle;

public class Main extends Activity implements SimpleGestureListener {

	private static String username = "";
	private static String password = "";
	private static String sessionName = "";
	private static String sessionId = "";

	private static String rootDirectory;
	private static String previousDirectory;
	private static String currentDirectory;

	private static final String baseUrl = "http://isensedev.cs.uml.edu/experiment.php?id=";
	private static final String tag = "main.java";

	private Vibrator vibrator;
	private TextView loginInfo;
	private TextView experimentLabel;
	private Button refresh;
	private Button upload;
	private TextView noData;
	private ImageView backImage;

	private static final int LOGIN_REQUESTED = 100;
	private static final int VIEW_DATA_REQUESTED = 101;
	private static final int EXPERIMENT_REQUESTED = 102;

	private RestAPI rapi;
	private Waffle w;
	private DataFieldManager dfm;
	
	private ProgressDialog dia;
	private SharedPreferences optionPrefs;

	private static boolean useMenu = true;
	private static boolean successLogin = false;

	private long uploadTime;
	public JSONArray data;

	public static Context mContext;

	private LinearLayout dataView;

	private ArrayList<File> checkedFiles;

	private SimpleGestureFilter detector;

	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);

		mContext = this;
		w = new Waffle(mContext);

		detector = new SimpleGestureFilter(this, this);

		rapi = RestAPI
				.getInstance(
						(ConnectivityManager) getSystemService(Context.CONNECTIVITY_SERVICE),
						getApplicationContext());
		rapi.useDev(true);
		
		optionPrefs = getSharedPreferences("options", 0);

		vibrator = (Vibrator) getSystemService(Context.VIBRATOR_SERVICE);

		checkedFiles = new ArrayList<File>();

		final SharedPreferences mUserPrefs = new ObscuredSharedPreferences(
				Main.mContext, Main.mContext.getSharedPreferences("USER_INFO",
						Context.MODE_PRIVATE));
		final SharedPreferences mExpPrefs = getSharedPreferences("eid", 0);

		String loginName = mUserPrefs.getString("username", "");
		if (loginName.length() >= 15)
			loginName = loginName.substring(0, 15) + "...";
		loginInfo = (TextView) findViewById(R.id.loginLabel);
		loginInfo.setText(getResources().getString(R.string.loggedInAs) + " "
				+ loginName);

		experimentLabel = (TextView) findViewById(R.id.experimentLabel);
		experimentLabel.setText(getResources().getString(
				R.string.usingExperiment)
				+ " " + mExpPrefs.getString("eid", ""));

		noData = (TextView) findViewById(R.id.noItems);

		backImage = (ImageView) findViewById(R.id.back_image);
		backImage.setOnClickListener(new OnClickListener() {

			public void onClick(View v) {

				previousDirectory(currentDirectory);
			}
		});

		dataView = (LinearLayout) findViewById(R.id.dataView);

		rootDirectory = Environment.getExternalStorageDirectory().getPath();
		previousDirectory = rootDirectory;
		currentDirectory = rootDirectory;

		boolean success;
		try {
			success = getFiles(Environment.getExternalStorageDirectory(),
					dataView);
		} catch (Exception e) {
			w.make(e.toString(), Waffle.IMAGE_X);
			success = false;
		}

		if (success) {
			noData.setVisibility(View.GONE);
			backImage.setVisibility(View.VISIBLE);
		} else {
			noData.setVisibility(View.VISIBLE);
			backImage.setVisibility(View.GONE);
		}

		refresh = (Button) findViewById(R.id.refresh);
		refresh.setOnClickListener(new OnClickListener() {

			public void onClick(View v) {

				boolean success;
				try {
					success = getFiles(new File(currentDirectory), dataView);

				} catch (Exception e) {
					w.make(e.toString(), Waffle.IMAGE_X);
					success = false;
				}

				if (!success) {
					Intent iSdFail = new Intent(mContext, SdCardFailure.class);
					startActivity(iSdFail);
				}

			}
		});

		upload = (Button) findViewById(R.id.upload);
		upload.setOnClickListener(new OnClickListener() {

			public void onClick(View v) {

				new UploadTask().execute();
			}
		});

	}

	long getUploadTime() {
		Calendar c = Calendar.getInstance();
		return (long) (c.getTimeInMillis());
	}

	@Override
	public void onPause() {
		super.onPause();
	}

	@Override
	public void onStop() {
		super.onStop();
	}

	@Override
	public void onStart() {
		super.onStart();
	}

	@Override
	public void onResume() {
		login();
		super.onResume();
	}

	@Override
	public void onBackPressed() {
		super.onBackPressed();
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		super.onCreateOptionsMenu(menu);

		MenuInflater inflater = getMenuInflater();
		inflater.inflate(R.menu.menu, menu);

		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item) {
		switch (item.getItemId()) {
		case R.id.menu_item_options:
			Intent iOptions = new Intent(mContext, Options.class);
			startActivity(iOptions);
			return true;
			
		case R.id.menu_item_experiment:
			Intent iExperiment = new Intent(mContext, Experiment.class);
			startActivityForResult(iExperiment, EXPERIMENT_REQUESTED);
			return true;
			
		case R.id.menu_item_login:
			Intent iLogin = new Intent(mContext, LoginActivity.class);
			startActivityForResult(iLogin, LOGIN_REQUESTED);
			return true;
		
		default:
			return super.onOptionsItemSelected(item);

		}
	}

	static int getApiLevel() {
		return android.os.Build.VERSION.SDK_INT;
	}

	@Override
	public void onActivityResult(int requestCode, int resultCode, Intent data) {
		super.onActivityResult(requestCode, resultCode, data);

		if (requestCode == LOGIN_REQUESTED) {
			if (resultCode == RESULT_OK) {
				String returnCode = data.getStringExtra("returnCode");

				if (returnCode.equals("Success")) {
					final SharedPreferences mPrefs = new ObscuredSharedPreferences(
							Main.mContext, Main.mContext.getSharedPreferences(
									"USER_INFO", Context.MODE_PRIVATE));
					String loginName = mPrefs.getString("username", "");
					if (loginName.length() >= 18)
						loginName = loginName.substring(0, 18) + "...";
					loginInfo.setText(getResources().getString(
							R.string.loggedInAs)
							+ " " + loginName);
					successLogin = true;
					w.make("Login successful.", Waffle.LENGTH_SHORT);
				} else if (returnCode.equals("Failed")) {
					successLogin = false;
					Intent i = new Intent(mContext, LoginActivity.class);
					startActivityForResult(i, LOGIN_REQUESTED);
				} else {
					// should never get here
				}

			}

		} else if (requestCode == VIEW_DATA_REQUESTED) {
			if (resultCode == RESULT_OK) {
				final SharedPreferences mPrefs = getSharedPreferences("eid", 0);
				Intent iUrl = new Intent(Intent.ACTION_VIEW);
				iUrl.setData(Uri.parse(baseUrl + mPrefs.getString("eid", "-1")));
				startActivity(iUrl);
			}

		} else if (requestCode == EXPERIMENT_REQUESTED) {
			if (resultCode == RESULT_OK) {
				String eid = data.getStringExtra("eid");
				final SharedPreferences mPrefs = getSharedPreferences("eid", 0);
				final SharedPreferences.Editor mEditor = mPrefs.edit();
				mEditor.putString("eid", eid).commit();
				experimentLabel.setText(getResources().getString(
						R.string.usingExperiment)
						+ " " + eid);
			}
		} 
	}

	private Runnable uploader = new Runnable() {

		public void run() {

			// Do rapi uploading stuff
			for (File f : checkedFiles) {
				uploadFile(f);
			}
		}
	};

	private class UploadTask extends AsyncTask<Void, Integer, Void> {

		@Override
		protected void onPreExecute() {

			vibrator.vibrate(250);
			dia = new ProgressDialog(Main.this);
			dia.setProgressStyle(ProgressDialog.STYLE_SPINNER);
			dia.setMessage("Uploading uPPT data set to iSENSE...");
			dia.setCancelable(false);
			dia.show();

		}

		@Override
		protected Void doInBackground(Void... voids) {

			uploader.run();

			publishProgress(100);
			return null;

		}

		@Override
		protected void onPostExecute(Void voids) {

			dia.setMessage("Done");
			dia.cancel();

			Intent iView = new Intent(mContext, ViewData.class);
			startActivityForResult(iView, VIEW_DATA_REQUESTED);
		}
	}

	private boolean getFiles(File dir, final LinearLayout dataView)
			throws Exception {

		String state = Environment.getExternalStorageState();
		if (!Environment.MEDIA_MOUNTED.equals(state)) {
			throw new Exception("Cannot Access External Storage.");
		}

		File[] files = dir.listFiles();
		if (files.equals(null))
			return false;
		else {
			dataView.removeAllViews();
			if (files.length == 0) {
				final TextView noData = new TextView(mContext);
				noData.setText("No files or directories.");
				noData.setPadding(5, 10, 5, 10);
				dataView.addView(noData);
			}
			for (int i = 0; i < files.length; i++) {
				final CheckedTextView ctv = new CheckedTextView(mContext);
				ctv.setText(getFileName(dir.getName(), files[i].toString()));
				ctv.setPadding(5, 10, 5, 10);
				ctv.setChecked(false);
				ctv.setOnClickListener(new OnClickListener() {

					public void onClick(View v) {
						File nextFile = new File(currentDirectory
								+ ctv.getText().toString());
						if (nextFile.isDirectory()) {
							previousDirectory = currentDirectory;
							boolean success;
							try {
								success = getFiles(nextFile, dataView);
								checkedFiles.removeAll(checkedFiles);
							} catch (Exception e) {
								w.make(e.toString(), Waffle.IMAGE_X);
								success = false;
							}
						} else {
							if (isCSV(ctv.getText().toString())) {
								ctv.toggle();
								if (ctv.isChecked()) {
									ctv.setCheckMarkDrawable(R.drawable.bluecheck);
									checkedFiles.add(nextFile);
								} else {
									ctv.setCheckMarkDrawable(0);
									checkedFiles.remove(nextFile);
								}
							} else w.make("This file type is not supported.  Please choose a valid \".csv\".", Waffle.IMAGE_X);
						}
					}

				});
				dataView.addView(ctv);
			}
		}
		currentDirectory = dir.toString();
		return true;
	}

	@Override
	public boolean dispatchTouchEvent(MotionEvent me) {
		this.detector.onTouchEvent(me);
		return super.dispatchTouchEvent(me);
	}

	public void onSwipe(int direction) {

		switch (direction) {

		case SimpleGestureFilter.SWIPE_RIGHT:
			if (optionPrefs.getBoolean("swipe", true))
				previousDirectory(currentDirectory);
			break;
		default:
			break;
		}
	}

	private void previousDirectory(String curr) {
		if (curr.equals(rootDirectory)) {
			w.make("Cannot go back from this point", Waffle.IMAGE_X);
		}
		else try {
			getFiles(new File(previousDirectory), dataView);
			currentDirectory = previousDirectory;
			previousDirectory = getParentDir(currentDirectory);
		} catch (Exception e) {
			w.make(e.toString(), Waffle.IMAGE_X);
		}
	}

	private boolean uploadFile(File sdFile) {
		if (sdFile.isDirectory() || sdFile.isHidden() || !sdFile.canRead())
			return false;
		BufferedReader fReader = null;

		try {
			fReader = new BufferedReader(new FileReader(sdFile));
			fReader.readLine();
			fReader.close();
		} catch (IOException e) {
			w.make(e.toString(), Waffle.IMAGE_X);
		}

		return false;
	}
	
	private String[] getOrder(String top) {
		
		LinkedList<String> order = new LinkedList<String>();
		String[] sdOrder = top.split(",");
		
		int length = sdOrder.length;
		if (length == 0)
			return null;
		
		final SharedPreferences mPrefs = getSharedPreferences("eid", 0);
		int eid = Integer.parseInt(mPrefs.getString("eid", "-1"));
		if (eid == -1)
			return null;
		
		dfm = new DataFieldManager(eid, rapi, mContext);
		dfm.getFieldOrder();
		
		for (String s : dfm.order) {
			for (int i = 0; i < sdOrder.length; i++) {
				boolean match = dfm.match(sdOrder[i], s);
				if (match) {
					order.add(sdOrder[i]);
					break;
				}
				if (i == (sdOrder.length - 1)) {
					order.add(null);
				}
				
			}
		}
		
		String[] ret = new String[order.size()];
		for (int i = 0; i < order.size(); i++)
			ret[i] = order.get(i);
		
		return ret;
	}

	private String getFileName(String current, String absolutePath) {
		return absolutePath.split(current)[1];
	}

	private String getParentDir(String absolutePath) {
		String dir = "";
		String[] sections = absolutePath.split("/");
		for (int i = 1; i < (sections.length - 1); i++) {
			dir += "/" + sections[i];
		}

		return dir;
	}
	
	private boolean isCSV(String fileName) {
		String[] splitName = fileName.split("\\.");
		String fileType = splitName[splitName.length - 1].toLowerCase();
		return fileType.equals("csv");
	}
	
	private boolean login() {
		final SharedPreferences loginPrefs = new ObscuredSharedPreferences(
				Main.mContext,
				Main.mContext.getSharedPreferences("USER_INFO",
						Context.MODE_PRIVATE));

		boolean success = false;
		if (!(loginPrefs.getString("username", "").equals("")))
			success = rapi.login(loginPrefs.getString("username", ""),
					loginPrefs.getString("password", ""));
		
		return success;
	}

	/*private void logDirectories() {
		Log.d(tag, rootDirectory + " - root");
		Log.d(tag, previousDirectory + " - prev");
		Log.d(tag, currentDirectory + "- curr");
	}*/
}
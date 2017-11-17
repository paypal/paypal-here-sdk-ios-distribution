package com.paypal.paypalretailsdk.ui.dialogs;

import java.util.ArrayList;
import java.util.List;

import com.eclipsesource.v8.V8;
import com.eclipsesource.v8.V8Array;
import com.eclipsesource.v8.V8Function;
import com.eclipsesource.v8.V8Object;
import com.eclipsesource.v8.V8Value;
import com.paypal.paypalretailsdk.PayPalRetailObject;
import com.paypal.paypalretailsdk.RetailSDK;
import com.paypal.paypalretailsdk.readers.common.StringUtil;

public class SDKDialogCommand
{
  enum CommandType
  {
    SHOW,
    DISMISS,
    SET_TITLE,
    SET_MESSAGE,
  }


  public class Audio
  {
    private String _file;
    private int _playCount;


    public Audio(String file, int playCount)
    {
      _file = file;
      _playCount = playCount;
    }


    public String getFile()
    {
      return _file;
    }


    public int getPlayCount()
    {
      return _playCount;
    }


    @Override
    public String toString()
    {
      return "<" + _file + ":" + _playCount + ">";
    }
  }


  public class ImageButton
  {
    private String _id;
    private String _imageIcon;

    public ImageButton(String id, String icon)
    {
      _id = id;
      _imageIcon = icon;
    }

    public String getId()
    {
      return _id;
    }


    public String getImageIcon()
    {
      return _imageIcon;
    }


    @Override
    public String toString()
    {
      return "<" + _imageIcon + ":" + _id + ">";
    }
  }

  private int _id;
  private String _title;
  private String _message;
  private String _img;
  private CommandType _commandType;
  private SDKDialogProxy _dialogProxy;
  private List<ImageButton> _imageButtons = new ArrayList<>();
  private List<String> _buttons = new ArrayList<>();
  private int _optionsButtonCount;
  private boolean _showActivity = false;
  private boolean _isCancellable = false;
  private V8Function _jsCallback;
  private static final int MAX_INT_ID = 1000000;
  private Audio _audio;

  private SDKDialogCommand(CommandType type, SDKDialogProxy dialogProxy)
  {
    _commandType = type;
    _dialogProxy = dialogProxy;
    _id = getNewId();
  }


  public SDKDialogCommand(SDKDialogProxy dialogProxy, CommandType type, V8Object options, V8Function callback)
  {
    this(type, dialogProxy);
    _title = (options.getType("title") == V8Value.STRING)
                         ? options.getString("title")
                         : null;

    _message = (options.getType("message") == V8Value.STRING)
               ? options.getString("message")
               : null;

    if (StringUtil.isEmpty(_title) && StringUtil.isEmpty(_message))
    {
      throw new RuntimeException("Title or message are required");
    }

    _jsCallback = callback.twin();
    _img = (options.getType("imageIcon") == V8Value.STRING)
               ? options.getString("imageIcon")
               : null;

    // Audio
    if (!options.getObject("audio").equals(V8.getUndefined()))
    {
      V8Object audio = options.getObject("audio");
      String audioFile = audio.getType("file") == V8Value.STRING
                  ? audio.getString("file")
                  : null;
      int audioLoopCount = audio.getType("playCount") == V8Value.INTEGER
                       ? audio.getInteger("playCount")
                       : 1;
      _audio = new Audio(audioFile, audioLoopCount);
    }

    // Options button
    V8Array buttons = PayPalRetailObject.getEngine().getEmptyArray();
    if (options.getType("buttons") == V8Value.V8_ARRAY)
    {
      buttons = options.getArray("buttons");
    }

    _optionsButtonCount = buttons.length();
    if (_optionsButtonCount > 0)
    {
      for (int i = 0; i < buttons.length(); i++)
      {
        String curBtn = buttons.getString(i);
        _buttons.add(curBtn);
      }
    }

    // Image buttons
    V8Array imageButtonIcons = PayPalRetailObject.getEngine().getEmptyArray();
    if (options.getType("buttonsImages") == V8Value.V8_ARRAY)
    {
      imageButtonIcons = options.getArray("buttonsImages");
    }
    V8Array imageButtonIds = PayPalRetailObject.getEngine().getEmptyArray();
    if (options.getType("buttonsIds") == V8Value.V8_ARRAY)
    {
      imageButtonIds = options.getArray("buttonsIds");
    }

    if (imageButtonIcons.length() != imageButtonIds.length())
    {
      throw new RuntimeException("Button Imgs length " + imageButtonIcons.length() + " does not match with buttons Ids lenght: " + imageButtonIds.length());
    }

    for (int i = 0; i < imageButtonIcons.length(); i++)
    {
      String imageIcon = imageButtonIcons.getString(i);
      String imageId = imageButtonIds.getString(i);
      _imageButtons.add(new ImageButton(imageId, imageIcon));
    }

    // Cancel button
    if (options.getType("cancel") == V8Value.STRING)
    {
      _buttons.add(options.getString("cancel"));
    }

    _showActivity = (options.getType("showActivity") == V8Value.BOOLEAN) && options.getBoolean("showActivity");
    _isCancellable = (options.getType("setCancellable") == V8Value.BOOLEAN) && options.getBoolean("setCancellable");
  }


  static SDKDialogCommand getDismissCommand(SDKDialogProxy dialogProxy)
  {
    return new SDKDialogCommand(CommandType.DISMISS, dialogProxy);
  }


  @Override
  public String toString()
  {
    return "Id: " + _id +
        "\nCommandType: " + _commandType +
        "\nTitle: '" + _title + "'" +
        "\nImage: " + _img +
        "\nMessage: " + _message +
        "\nButton Ids: " + StringUtil.join(_buttons, ',') +
        "\nImage Buttons: " + StringUtil.join(_imageButtons, ',') +
        "\nOptions Button Count: " + _optionsButtonCount +
        "\nShowActivity: " + _showActivity +
        "\nIsCancellable: " + _isCancellable +
        "\nAudio: " + _audio;
  }


  private int getNewId()
  {
    if (_id > MAX_INT_ID)
    {
      _id = 0;
    }
    return ++_id;
  }


  public CommandType getCommandType()
  {
    return _commandType;
  }


  public String getTitle()
  {
    return _title;
  }


  public String getMessage()
  {
    return _message;
  }


  public String getImg()
  {
    return _img;
  }


  public List<ImageButton> getButtonImgs()
  {
    return _imageButtons;
  }


  public List<String> getButtons()
  {
    return _buttons;
  }


  public boolean showProgressSpinner()
  {
    return _showActivity;
  }


  public boolean isCancellable()
  {
    return _isCancellable;
  }


  public Audio getAudio()
  {
    return _audio;
  }


  public void onClick(final int index)
  {
    if (_jsCallback == null || _dialogProxy == null)
    {
      return;
    }

    PayPalRetailObject.getEngine().getExecutor().run(new Runnable()
    {
      @Override
      public void run()
      {
        _jsCallback.call(_dialogProxy.getJsObject(), RetailSDK.jsArgs().push(_dialogProxy.getJsObject()).push(index));
        release();
      }
    });
  }

  public void release()
  {
    if (_jsCallback != null)
    {
      _jsCallback.release();
      _jsCallback = null;
    }
  }
}
